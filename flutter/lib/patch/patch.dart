import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/patch/patch_canvas.dart';

import 'dart:io';
import 'dart:async';

import 'pin.dart';
import '../plugin/plugin.dart';
import 'node.dart';
import 'module.dart';
import 'right_click.dart';
import '../preset/info.dart';

import '../bindings/api/graph.dart' as api;
import '../bindings/api/cable.dart';
import '../bindings/api/node.dart' as rust_node;

/* LIBRARY */

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

// Callback types - simplified without undo/redo
typedef NodeCallback = void Function(Module module, Offset position);
typedef CableCallback = void Function(Pin start, Pin end);
typedef NodeRemoveCallback = void Function(NodeEditor node);
typedef CableRemoveCallback = void Function(Pin start, Pin end);
typedef BatchNodeRemoveCallback = void Function(List<NodeEditor> nodes);

class PatchEditor extends StatefulWidget {
  PatchEditor({
    required this.presetInfo,
    required this.plugins,
  }) : super(key: UniqueKey());

  final PresetInfo presetInfo;
  final List<Plugin> plugins;

  @override
  _PatchEditor createState() => _PatchEditor();
}

class _PatchEditor extends State<PatchEditor> with SingleTickerProviderStateMixin {

  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;

  final focusNode = FocusNode();
  late final Ticker _ticker;
  
  // Selected node IDs managed in state
  List<int> selectedNodeIds = [];
  
  // New cable being drawn
  Pin? newCableStart;
  Pin? newCableEndPin;
  Offset? newCableEnd;
  
  // Notifier to trigger cable repaints when nodes move
  final ChangeNotifier _cableRepaintNotifier = ChangeNotifier();
  
  // Rust patch and transformation controller (moved from SimplePatchWidget)
  rust_patch.Patch? _rustPatch;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(tick);
    _ticker.start();
    _loadPatch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cableRepaintNotifier.dispose();
    _transformationController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // Cache for NodeEditor widgets to prevent recreation
  Map<int, NodeEditor> _nodeEditorCache = {};
  int _cacheVersion = 0;
  
  // Build NodeEditor widgets from rust patch nodes
  List<NodeEditor> _buildNodeEditors() {
    if (_rustPatch == null) return [];
    
    var rustNodes = _rustPatch!.getNodes();
    List<NodeEditor> nodeEditors = [];
    Set<int> currentNodeIds = {};
    
    for (var rustNode in rustNodes) {
      currentNodeIds.add(rustNode.id);
      
      // Check if we already have this node in cache
      if (_nodeEditorCache.containsKey(rustNode.id)) {
        nodeEditors.add(_nodeEditorCache[rustNode.id]!);
        continue;
      }
      
      try {
        // Convert Rust module to Flutter module
        var rustModule = rustNode.module;
        var module = Module.fromRustModule(rustModule);
        
        var position = Offset(rustNode.position.$1, rustNode.position.$2);
        
        var nodeEditor = NodeEditor(
          key: ValueKey('node_${rustNode.id}'), // Add key for widget identity
          module: module,
          rustNode: rustNode,
          onAddConnector: addCable,
          onRemoveConnections: removeConnectionsTo,
          position: position,
          onNewCableDrag: _onNewCableDrag,
          onNewCableSetStart: _onNewCableSetStart,
          onNewCableSetEnd: _onNewCableSetEnd,
          onNewCableReset: _onNewCableReset,
          onAddNewCable: _onAddNewCable,
          onPositionChanged: _onNodePositionChanged,
        );
        
        _nodeEditorCache[rustNode.id] = nodeEditor;
        nodeEditors.add(nodeEditor);
      } catch (e) {
        print("Failed to create node editor: $e");
      }
    }
    
    // Remove cached nodes that no longer exist
    _nodeEditorCache.removeWhere((id, editor) => !currentNodeIds.contains(id));

    return nodeEditors;
  }
  
  // Clear cache when nodes change
  void _invalidateNodeCache() {
    _nodeEditorCache.clear();
    _cacheVersion++;
  }


  // New cable callback methods
  void _onNewCableDrag(Offset globalOffset) {
    setState(() {
      // Convert global coordinates to patch coordinates
      // The globalOffset is relative to the screen, we need to convert to patch space
      newCableEnd = globalOffset;
    });
  }
  
  void _onNewCableSetStart(Pin pin) {
    setState(() {
      newCableStart = pin;
      newCableEndPin = null;
      newCableEnd = null;
    });
  }
  
  void _onNewCableSetEnd(Pin? pin) {
    setState(() {
      newCableEndPin = pin;
    });
  }
  
  void _onNewCableReset() {
    setState(() {
      newCableStart = null;
      newCableEndPin = null;
      newCableEnd = null;
    });
  }
  
  void _onAddNewCable() {
    if (newCableStart != null && newCableEndPin != null) {
      // Complete the cable connection
      addCable(newCableStart!, newCableEndPin!);
    }
    
    // Reset the new cable state
    setState(() {
      newCableStart = null;
      newCableEndPin = null;
      newCableEnd = null;
    });
  }

  Future<void> _loadPatch() async {
    _rustPatch = rust_patch.Patch();
    
    // Try to load existing patch file
    if (await widget.presetInfo.patchFile.exists()) {
      try {
        var contents = await widget.presetInfo.patchFile.readAsString();
        await _rustPatch!.load(jsonStr: contents);
      } catch (e) {
        print("Failed to load patch: $e");
      }
    }
    
    // Update node ID counter to avoid conflicts with loaded nodes
    if (_rustPatch != null) {
      var maxId = 0;
      for (var node in _rustPatch!.getNodes()) {
        if (node.id > maxId) {
          maxId = node.id;
        }
      }
      _nextNodeId = maxId + 1;
    }
    
    // Trigger rebuild to show loaded nodes
    setState(() {});
  }

  // Node ID counter to avoid conflicts
  static int _nextNodeId = 1;
  
  // Callback implementations (moved from SimplePatchWidget)
  void _onAddNode(Module module, Offset position) {
    // Create Rust node and add to patch
    var rustModule = module.toRustModule();
    var nodeId = _nextNodeId++;
    var rustNode = rust_node.Node.from(
      id: nodeId,
      module: rustModule,
      position: (position.dx, position.dy),
    );
    
    if (rustNode != null) {
      _rustPatch!.addNode(node: rustNode);
      _savePatch();
      
      _invalidateNodeCache();
      // Trigger rebuild to show new node
      setState(() {});
    }
  }
  
  void _onRemoveNode(NodeEditor node) {
    if (node.rustNode != null) {
      _rustPatch!.removeNode(node: node.rustNode!);
      _savePatch();
      
      _invalidateNodeCache();
      setState(() {});
    }
  }
  
  void _onAddCable(Pin start, Pin end) {
    try {
      // Create a temporary graph to generate the cable
      var tempGraph = api.Graph();
      tempGraph.addCable(
        srcNode: start.node.rustNode!,
        srcEndpoint: start.endpoint,
        dstNode: end.node.rustNode!,
        dstEndpoint: end.endpoint,
      );
      
      // Get the created cable from the graph
      var cables = tempGraph.cables;
      if (cables.isNotEmpty) {
        var cable = cables.first;
        _rustPatch!.addCable(cable: cable);
        print("Added cable: ${start.node.module.name} -> ${end.node.module.name}");
        _savePatch();
        setState(() {}); // Trigger rebuild to show new cable
      }
    } catch (e) {
      print("Failed to add cable: $e");
    }
  }
  
  void _onRemoveCable(Pin start, Pin end) {
    try {
      // Find the cable to remove by matching endpoints
      var cables = _rustPatch!.getCables();
      for (var cable in cables) {
        bool isMatch = false;
        
        // Check if this cable matches the pins (either direction)
        if ((cable.source.node.id == start.node.rustNode!.id &&
             cable.source.endpoint.type == start.endpoint.type &&
             cable.source.endpoint.annotation == start.endpoint.annotation &&
             cable.destination.node.id == end.node.rustNode!.id &&
             cable.destination.endpoint.type == end.endpoint.type &&
             cable.destination.endpoint.annotation == end.endpoint.annotation) ||
            (cable.source.node.id == end.node.rustNode!.id &&
             cable.source.endpoint.type == end.endpoint.type &&
             cable.source.endpoint.annotation == end.endpoint.annotation &&
             cable.destination.node.id == start.node.rustNode!.id &&
             cable.destination.endpoint.type == start.endpoint.type &&
             cable.destination.endpoint.annotation == start.endpoint.annotation)) {
          isMatch = true;
        }
        
        if (isMatch) {
          _rustPatch!.removeCable(cable: cable);
          print("Removed cable");
          _savePatch();
          setState(() {}); // Trigger rebuild to hide removed cable
          break;
        }
      }
    } catch (e) {
      print("Failed to remove cable: $e");
    }
  }
  
  void _onBatchRemoveNodes(List<int> nodeIdsToRemove) {
    var rustNodes = _rustPatch!.getNodes();
    for (var nodeId in nodeIdsToRemove) {
      var nodeToRemove = rustNodes.where((n) => n.id == nodeId).firstOrNull;
      if (nodeToRemove != null) {
        _rustPatch!.removeNode(node: nodeToRemove);
      }
    }
    
    _savePatch();
    _invalidateNodeCache();
    setState(() {});
  }
  
  Future<void> _savePatch() async {
    try {
      var jsonStr = await _rustPatch!.save();
      await widget.presetInfo.patchFile.writeAsString(jsonStr);
      print("Saved patch file: ${widget.presetInfo.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
  }
  
  void _onNodePositionChanged(NodeEditor node, Offset newPosition) {
    // Update the position in the Rust patch directly by node ID
    if (node.rustNode != null) {
      // Update the node's position in the patch (not the clone)
      _rustPatch!.updateNodePosition(
        nodeId: node.rustNode!.id, 
        position: (newPosition.dx, newPosition.dy)
      );
      
      // Save immediately since this is only called on drag end
      _savePatch();
    }
  }

  void removeNode(NodeEditor node) {
    _onRemoveNode(node);
  }

  void tick(Duration elapsed) {
    var nodeEditors = _buildNodeEditors();
    for (var node in nodeEditors) {
      for (var widget in node.widgets) {
        widget.tick(elapsed);
      }
    }
    
    // Notify cable painter to repaint
    _cableRepaintNotifier.notifyListeners();
  }

  void updatePlayback() {
    // Update the UI
    setState(() {});

    // Create a new graph
    var graph = api.Graph.new();

    // Add all the cables from the Rust patch to the graph
    var rustCables = _rustPatch!.getCables();
    for (var cable in rustCables) {
      graph.addCable(
        srcNode: cable.source.node,
        srcEndpoint: cable.source.endpoint,
        dstNode: cable.destination.node,
        dstEndpoint: cable.destination.endpoint,
      );
    }

    // Add all the nodes to the graph
    var rustNodes = _rustPatch!.getNodes();
    for (var node in rustNodes) {
      graph.addNode(node: node);
    }

    // Update the playback graph
    api.setPatch(graph: graph);
  }

  double roundToGrid(double value) {
    const gridSize = 20.0;
    return (value / gridSize).round() * gridSize;
  }
  
  void addModule(Module module, Offset p) {
    Offset position = Offset(roundToGrid(p.dx), roundToGrid(p.dy));
    _onAddNode(module, position);
  }

  void addCable(Pin start, Pin end) {
    // Check if connection is supported
    if (api.isConnectionSupported(
      srcNode: start.node.rustNode!,
      srcEndpoint: start.endpoint,
      dstNode: end.node.rustNode!,
      dstEndpoint: end.endpoint,
    )) {
      _onAddCable(start, end);
    } else {
      print("Connection not supported");
    }
  }

  void removeConnectionsTo(Pin pin) {
    // Find cables to remove from the Rust patch
    var cablesToRemove = _rustPatch!.getCables()
        .where((cable) => 
          _pinMatchesConnection(pin, cable.source) || 
          _pinMatchesConnection(pin, cable.destination))
        .toList();
    
    for (var cable in cablesToRemove) {
      // Find the other pin for the callback
      Pin? otherPin;
      if (_pinMatchesConnection(pin, cable.source)) {
        // Find the destination pin
        var nodeEditors = _buildNodeEditors();
        var destNode = nodeEditors.firstWhere((n) => n.rustNode?.id == cable.destination.node.id);
        otherPin = destNode.pins.firstWhere((p) => 
          p.endpoint.type == cable.destination.endpoint.type &&
          p.endpoint.annotation == cable.destination.endpoint.annotation);
      } else {
        // Find the source pin
        var nodeEditors = _buildNodeEditors();
        var srcNode = nodeEditors.firstWhere((n) => n.rustNode?.id == cable.source.node.id);
        otherPin = srcNode.pins.firstWhere((p) => 
          p.endpoint.type == cable.source.endpoint.type &&
          p.endpoint.annotation == cable.source.endpoint.annotation);
      }
      
      if (otherPin != null) {
        _onRemoveCable(pin, otherPin);
      }
    }
  }
  
  bool _pinMatchesConnection(Pin pin, Connection connection) {
    if (pin.node.rustNode?.id != connection.node.id) return false;
    return pin.endpoint.type == connection.endpoint.type && 
           pin.endpoint.annotation == connection.endpoint.annotation;
  }
  
  // Keyboard event handlers
  void _handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent) {
      _handleUndoRedo(e);
      _handleDeleteNodes(e);
    }
  }
  
  void _handleUndoRedo(KeyDownEvent e) {
    // Undo/redo functionality removed for now
    // Can be re-implemented later if needed
  }
  
  void _handleDeleteNodes(KeyDownEvent e) {
    if (e.logicalKey == LogicalKeyboardKey.delete ||
        e.logicalKey == LogicalKeyboardKey.backspace) {
      if (selectedNodeIds.isNotEmpty) {
        _onBatchRemoveNodes(selectedNodeIds.toList());
        
        // Clear selection after removal
        setState(() {
          selectedNodeIds = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        setState(() {
          rightClickOffset = details.localPosition;
          showRightClickMenu = true;
        });
      },
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.2,
            maxScale: 1.5,
            panEnabled: true,
            scaleEnabled: true,
            clipBehavior: Clip.hardEdge,
            constrained: false,
            transformationController: _transformationController,
            onInteractionUpdate: (details) {
              if (showRightClickMenu) {
                setState(() {
                  showRightClickMenu = false;
                });
              }

              if (selectedNodeIds.isNotEmpty) {
                setState(() {
                  selectedNodeIds = [];
                });
              }
            },
            child: PatchViewer(
              nodes: _buildNodeEditors(),
              cables: _rustPatch!.getCables(),
              newCableStart: newCableStart,
              newCableEnd: newCableEnd,
              repaintNotifier: _cableRepaintNotifier,
              focusNode: focusNode,
              onPointerDown: (e) {
                moduleAddPosition = e.localPosition;
              },
              onTap: () {
                if (showRightClickMenu) {
                  setState(() {
                    showRightClickMenu = false;
                  });
                }

                if (selectedNodeIds.isNotEmpty) {
                  setState(() {
                    selectedNodeIds = [];
                  });
                }
              },
              onKeyEvent: _handleKeyEvent,
            ),
          ),
          Visibility(
            visible: showRightClickMenu,
            child: Positioned(
              left: rightClickOffset.dx,
              top: rightClickOffset.dy,
              child: RightClickView(
                plugins: widget.plugins,
                onAddModule: (info) {
                  addModule(info, moduleAddPosition);
                  setState(() {
                    showRightClickMenu = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/patch/patch_canvas.dart';

import 'dart:io';

import 'pin.dart';
import '../plugin/plugin.dart';
import 'node.dart';
import 'module.dart';
import 'right_click.dart';

import '../bindings/api/graph.dart' as api;
import '../bindings/api/cable.dart';

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
    required this.rustPatch,
    required this.plugins,
    required this.transformationController,
    required this.onAddNode,
    required this.onRemoveNode,
    required this.onAddCable,
    required this.onRemoveCable,
    required this.onBatchRemoveNodes,
  }) : super(key: UniqueKey());

  final rust_patch.Patch rustPatch;
  final List<Plugin> plugins;
  final TransformationController transformationController;
  
  // Callbacks
  final NodeCallback onAddNode;
  final NodeRemoveCallback onRemoveNode;
  final CableCallback onAddCable;
  final CableRemoveCallback onRemoveCable;
  final BatchNodeRemoveCallback onBatchRemoveNodes;

  @override
  _PatchEditor createState() => _PatchEditor();
}

class _PatchEditor extends State<PatchEditor> with SingleTickerProviderStateMixin {

  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;

  final focusNode = FocusNode();
  late final Ticker _ticker;
  
  // Selected nodes managed in state
  List<NodeEditor> selectedNodes = [];
  
  // Current nodes (derived from Rust patch)
  List<NodeEditor> nodes = [];
  
  // New cable being drawn
  Pin? newCableStart;
  Pin? newCableEndPin;
  Offset? newCableEnd;
  
  // Notifier to trigger cable repaints when nodes move
  final ChangeNotifier _cableRepaintNotifier = ChangeNotifier();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(tick);
    _ticker.start();
    _loadFromRustPatch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cableRepaintNotifier.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _loadFromRustPatch() {
    // Get nodes from Rust patch and create Flutter NodeEditor wrappers
    var rustNodes = widget.rustPatch.getNodes();
    List<NodeEditor> newNodes = [];
    Map<int, NodeEditor> nodeMap = {};
    
    for (var rustNode in rustNodes) {
      try {
        // Convert Rust module to Flutter module
        var rustModule = rustNode.module;
        var module = Module.fromRustModule(rustModule);
        
        var position = Offset(rustNode.position.$1, rustNode.position.$2);
        
        var nodeEditor = NodeEditor(
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
        );
        
        nodeMap[rustNode.id] = nodeEditor;
        newNodes.add(nodeEditor);
      } catch (e) {
        print("Failed to load node: $e");
      }
    }

    setState(() {
      nodes = newNodes;
    });
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

  void removeNode(NodeEditor node) {
    widget.onRemoveNode(node);
  }

  void tick(Duration elapsed) {
    for (var node in nodes) {
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
    var rustCables = widget.rustPatch.getCables();
    for (var cable in rustCables) {
      graph.addCable(
        srcNode: cable.source.node,
        srcEndpoint: cable.source.endpoint,
        dstNode: cable.destination.node,
        dstEndpoint: cable.destination.endpoint,
      );
    }

    // Add all the nodes to the graph
    for (var node in nodes) {
      // Skip if node is null
      if (node.rustNode == null) continue;

      graph.addNode(node: node.rustNode!);
    }

    // Update the playback graph
    api.setPatch(graph: graph);
  }

  void addModule(Module module, Offset p) {
    Offset position = Offset(roundToGrid(p.dx), roundToGrid(p.dy));
    widget.onAddNode(module, position);
  }

  void addCable(Pin start, Pin end) {
    // Check if connection is supported
    if (api.isConnectionSupported(
      srcNode: start.node.rustNode!,
      srcEndpoint: start.endpoint,
      dstNode: end.node.rustNode!,
      dstEndpoint: end.endpoint,
    )) {
      widget.onAddCable(start, end);
    } else {
      print("Connection not supported");
    }
  }

  void removeConnectionsTo(Pin pin) {
    // Find cables to remove from the Rust patch
    var cablesToRemove = widget.rustPatch.getCables()
        .where((cable) => 
          _pinMatchesConnection(pin, cable.source) || 
          _pinMatchesConnection(pin, cable.destination))
        .toList();
    
    for (var cable in cablesToRemove) {
      // Find the other pin for the callback
      Pin? otherPin;
      if (_pinMatchesConnection(pin, cable.source)) {
        // Find the destination pin
        var destNode = nodes.firstWhere((n) => n.rustNode?.id == cable.destination.node.id);
        otherPin = destNode.pins.firstWhere((p) => 
          p.endpoint.type == cable.destination.endpoint.type &&
          p.endpoint.annotation == cable.destination.endpoint.annotation);
      } else {
        // Find the source pin
        var srcNode = nodes.firstWhere((n) => n.rustNode?.id == cable.source.node.id);
        otherPin = srcNode.pins.firstWhere((p) => 
          p.endpoint.type == cable.source.endpoint.type &&
          p.endpoint.annotation == cable.source.endpoint.annotation);
      }
      
      if (otherPin != null) {
        widget.onRemoveCable(pin, otherPin);
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
      if (selectedNodes.isNotEmpty) {
        widget.onBatchRemoveNodes(selectedNodes.toList());
        
        // Clear selection after removal
        setState(() {
          selectedNodes = [];
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
            transformationController: widget.transformationController,
            onInteractionUpdate: (details) {
              if (showRightClickMenu) {
                setState(() {
                  showRightClickMenu = false;
                });
              }

              if (selectedNodes.isNotEmpty) {
                setState(() {
                  selectedNodes = [];
                });
              }
            },
            child: PatchViewer(
              nodes: nodes,
              cables: widget.rustPatch.getCables(),
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

                if (selectedNodes.isNotEmpty) {
                  setState(() {
                    selectedNodes = [];
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
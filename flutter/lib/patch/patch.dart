import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/patch/painters.dart';

import 'dart:io';
import 'dart:async';

import '../bindings/api/module.dart';
import 'pin.dart';
import '../plugin/plugin.dart';
import 'node.dart';
import 'right_click.dart';
import '../preset/info.dart';
import '../titleBar.dart';

import '../bindings/api/io.dart';
import '../bindings/api/cable.dart';
import '../bindings/api/node.dart' as rust_node;
import '../bindings/api/endpoint.dart';
import '../bindings/api/patch.dart';

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
    required this.patch,
    this.audioManager,
  }) : super(key: UniqueKey());

  final PresetInfo presetInfo;
  final List<Plugin> plugins;
  final Patch patch;
  final AudioManager? audioManager;

  @override
  _PatchEditor createState() => _PatchEditor();
}

class _PatchEditor extends State<PatchEditor> {
  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;

  final focusNode = FocusNode();
  
  int _nextNodeId = 1;
  
  // Selected nodes managed in state
  List<rust_node.Node> selectedNodes = [];
  // Node & cable lists are owned locally; we do not store a long-lived Patch
  late List<rust_node.Node> _nodes;
  late List<Cable> _cables;
  
  // New cable being drawn
  Pin? newCableStart;
  Pin? newCableEndPin;
  Offset? newCableEnd;
  
  // Notifier to trigger cable repaints when nodes move
  final ChangeNotifier _cableRepaintNotifier = ChangeNotifier();
  
  // Transformation controller
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    // Initialize local state from incoming Patch once
    _nodes = [...widget.patch.nodes];
    _cables = [...widget.patch.cables];
    // Initialize next node id to one greater than the current maximum
    int maxId = 0;
    for (final n in _nodes) {
      if (n.id > maxId) maxId = n.id;
    }
    _nextNodeId = (maxId + 1);
  }
  
  @override
  void dispose() {
    _cableRepaintNotifier.dispose();
    _transformationController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // Build NodeEditor widgets
  List<Widget> _buildNodeEditors() {
    return _nodes.map((node) {
      return NodeEditor(
        // No key - let widgets be recreated fresh
        node: node,
        onSave: _savePatch,
        isEndpointConnected: _isEndpointConnected,
        onPositionChanged: _onNodePositionChanged,
        onAddConnector: addCable,
        onRemoveConnections: removeConnectionsTo,
        onNewCableDrag: _onNewCableDrag,
        onNewCableSetStart: _onNewCableSetStart,
        onNewCableSetEnd: _onNewCableSetEnd,
        onNewCableReset: _onNewCableReset,
        onAddNewCable: _onAddNewCable,
        isSelected: selectedNodes.any((selectedNode) => selectedNode.id == node.id),
        onToggleSelection: _toggleNodeSelection,
        onCableRepaintNeeded: () => _cableRepaintNotifier.notifyListeners(),
      );
    }).toList();
  }

  bool _isEndpointConnected(rust_node.Node node, NodeEndpoint endpoint) {
    for (final cable in _cables) {
      if (endpoint.isInput) {
        final dst = cable.destination;
        if (dst.node.id == node.id &&
            dst.endpoint.isInput == true &&
            dst.endpoint.type == endpoint.type &&
            dst.endpoint.annotation == endpoint.annotation) {
          return true;
        }
      } else {
        final src = cable.source;
        if (src.node.id == node.id &&
            src.endpoint.isInput == false &&
            src.endpoint.type == endpoint.type &&
            src.endpoint.annotation == endpoint.annotation) {
          return true;
        }
      }
    }
    return false;
  }
  void _onNodePositionChanged(rust_node.Node node) {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      final updated = [..._nodes];
      updated[index] = node;
      setState(() {
        _nodes = updated;
      });
    }
  }


  // New cable callback methods
  void _onNewCableDrag(Offset globalOffset) {
    setState(() {
      // Subtract the top app bar height so viewport-local Y is correct for toScene()
      newCableEnd = Offset(globalOffset.dx, globalOffset.dy - TitleBar.height);
    });
  }
  
  void _onNewCableSetStart(Pin pin) {
    print("Cable drag started from pin");
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

  // Callback implementations
  void _onAddNode(Module module, Offset position) {
    // Create Rust node directly
    try {
      var node = rust_node.Node.fromModule(
        module: module,
        position: (position.dx, position.dy),
      );
      
      if (node != null) {
        node.id = _nextNodeId++;
        setState(() {
          _nodes = [..._nodes, node];
        });
        
        _savePatch();
        updatePlayback();
      }
    } catch (e) {
      print("Failed to add node: $e");
    }
  }
  
  void _onAddCable(Pin start, Pin end) {
    // Create cable using Node and NodeEndpoint objects
    var cable = Cable(
      srcNode: start.node,
      srcEndpoint: start.endpoint,
      dstNode: end.node,
      dstEndpoint: end.endpoint,
    );
    
    try {
      setState(() {
        _cables = [..._cables, cable];
      });
      
      _savePatch();
      updatePlayback();
    } catch (e) {
      print("Failed to create cable: $e");
    }
  }
  
  void _onBatchRemoveNodes(List<rust_node.Node> nodesToRemove) {
    setState(() {
      final remainingNodes = _nodes
          .where((n) => !nodesToRemove.any((r) => r.id == n.id))
          .toList();

      final remainingCables = _cables
          .where((cable) => !nodesToRemove.any((node) =>
              cable.source.node.id == node.id ||
              cable.destination.node.id == node.id))
          .toList();

      _nodes = remainingNodes;
      _cables = remainingCables;
    });
    
    _savePatch();
    updatePlayback();
  }
  
  Future<void> _savePatch() async {
    try {
      final nodesJson = _nodes
          .map((n) => jsonDecode(n.toJson()) as Map<String, dynamic>)
          .toList();

      final cablesJson = _cables
          .map((c) => {
                'srcNodeId': c.source.node.id,
                'srcAnnotation': c.source.endpoint.annotation,
                'dstNodeId': c.destination.node.id,
                'dstAnnotation': c.destination.endpoint.annotation,
              })
          .toList();

      final jsonStr = jsonEncode({
        'nodes': nodesJson,
        'cables': cablesJson,
      });
      await widget.presetInfo.patchFile.writeAsString(jsonStr);
      print("Saved patch file: ${widget.presetInfo.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
  }
  

  void removeNode(rust_node.Node node) {
    setState(() {
      final remainingNodes = _nodes
          .where((n) => n.id != node.id)
          .toList();
      final remainingCables = _cables
          .where((cable) =>
              cable.source.node.id != node.id &&
              cable.destination.node.id != node.id)
          .toList();
      _nodes = remainingNodes;
      _cables = remainingCables;
    });
    
    _savePatch();
    updatePlayback();
  }

  void tick(Duration elapsed) {
    // Node widgets can handle their own ticking if needed
    // Notify cable painter to repaint
    _cableRepaintNotifier.notifyListeners();
  }

  void updatePlayback() {
    print("Updating patch in AudioManager with ${_nodes.length} nodes, ${_cables.length} cables");

    try {
      final patch = Patch();
      // Build patch incrementally using borrowed references to avoid disposing Dart handles
      try { patch.clear(); } catch (_) {}
      for (final n in _nodes) {
        patch.addNode(node: n);
      }
      for (final c in _cables) {
        patch.addCable(cable: c);
      }
      widget.audioManager!.setPatch(patch: patch);
    } catch (e) {
      print("Error updating patch in AudioManager: $e");
    }
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
    // Connection validation is handled by the Cable constructor
    _onAddCable(start, end);
  }

  void removeConnectionsTo(Pin pin) {
    // Find cables to remove
    setState(() {
      final updatedCables = _cables
          .where((cable) =>
              !_pinMatchesConnection(pin, cable.source) &&
              !_pinMatchesConnection(pin, cable.destination))
          .toList();
      _cables = updatedCables;
    });
    
    _savePatch();
    updatePlayback();
  }
  
  bool _pinMatchesConnection(Pin pin, Connection connection) {
    if (pin.node.id != connection.node.id) return false;
    
    // Compare endpoints directly
    return pin.endpoint.isInput == connection.endpoint.isInput &&
           pin.endpoint.type == connection.endpoint.type && 
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
        _onBatchRemoveNodes(selectedNodes.toList());
        
        // Clear selection after removal
        setState(() {
          selectedNodes = [];
        });
      }
    }
  }
  
  void _toggleNodeSelection(rust_node.Node node) {
    setState(() {
      var existingIndex = selectedNodes.indexWhere((selectedNode) => selectedNode.id == node.id);
      if (existingIndex >= 0) {
        selectedNodes.removeAt(existingIndex);
      } else {
        selectedNodes.add(node);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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

              if (selectedNodes.isNotEmpty) {
                setState(() {
                  selectedNodes = [];
                });
              }
            },
            child: Listener(
              onPointerDown: (e) {
                // Convert to scene coordinates for node placement in the transformed space
                moduleAddPosition = _transformationController.toScene(e.localPosition);
              },
              child: GestureDetector(
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
                child: KeyboardListener(
                  focusNode: focusNode,
                  autofocus: true,
                  onKeyEvent: _handleKeyEvent,
                  child: SizedBox(
                    width: 10000,
                    height: 10000,
                    child: CustomPaint(
                      painter: GridPainter(),
                      child: Stack(
                        children: <Widget>[
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: CablePainter(
                          nodes: _nodes,
                          cables: _cables,
                                repaint: _cableRepaintNotifier,
                              ),
                              size: const Size(10000, 10000),
                            ),
                          ),
                          if (newCableStart != null && newCableEnd != null)
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: NewCablePainter(
                                  startPin: newCableStart!,
                                  endOffset: newCableEnd!,
                                  transformationController: _transformationController,
                                ),
                                size: const Size(10000, 10000),
                              ),
                            ),
                          // Build NodeEditor widgets from patch nodes
                          ..._buildNodeEditors(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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

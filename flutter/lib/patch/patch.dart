import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/patch/painters.dart';

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
    required this.patch,
  }) : super(key: UniqueKey());

  final PresetInfo presetInfo;
  final List<Plugin> plugins;
  final rust_patch.Patch patch;

  @override
  _PatchEditor createState() => _PatchEditor();
}

class _PatchEditor extends State<PatchEditor> {
  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;

  final focusNode = FocusNode();
  
  // Selected node IDs managed in state
  List<int> selectedNodeIds = [];
  
  // New cable being drawn
  Pin? newCableStart;
  Pin? newCableEndPin;
  Offset? newCableEnd;
  
  // Notifier to trigger cable repaints when nodes move
  final ChangeNotifier _cableRepaintNotifier = ChangeNotifier();
  
  // Rust patch and transformation controller (moved from SimplePatchWidget)
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
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
    return widget.patch.getNodes().map((rustNode) {
      return NodeEditor(
        key: ValueKey(rustNode.id), // Use node ID as stable key
        node: rustNode,
        onSave: _savePatch,
        onAddConnector: addCable,
        onRemoveConnections: removeConnectionsTo,
        onNewCableDrag: _onNewCableDrag,
        onNewCableSetStart: _onNewCableSetStart,
        onNewCableSetEnd: _onNewCableSetEnd,
        onNewCableReset: _onNewCableReset,
        onAddNewCable: _onAddNewCable,
      );
    }).toList();
  }


  // New cable callback methods
  void _onNewCableDrag(Offset globalOffset) {
    setState(() {
      // For now, use the global offset directly - may need coordinate conversion later
      newCableEnd = globalOffset;
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
      widget.patch.addNode(node: rustNode);
      _savePatch();
      
      // Trigger rebuild to show new node
      setState(() {});
    }
  }
  
  void _onAddCable(Pin start, Pin end) {
    var cable = Cable.new(
      srcNode: start.node,
      srcEndpoint: start.endpoint,
      dstNode: end.node,
      dstEndpoint: end.endpoint,
    );

    widget.patch.addCable(cable: cable);
  }
  
  void _onBatchRemoveNodes(List<int> nodeIdsToRemove) {
    var rustNodes = widget.patch.getNodes();
    for (var nodeId in nodeIdsToRemove) {
      var nodeToRemove = rustNodes.where((n) => n.id == nodeId).firstOrNull;
      if (nodeToRemove != null) {
        widget.patch.removeNode(node: nodeToRemove);
      }
    }
    
    _savePatch();
    setState(() {});
  }
  
  Future<void> _savePatch() async {
    try {
      var jsonStr = await widget.patch.save();
      await widget.presetInfo.patchFile.writeAsString(jsonStr);
      print("Saved patch file: ${widget.presetInfo.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
  }
  

  void removeNode(rust_node.Node node) {
    widget.patch.removeNode(node: node);
    _savePatch();
    setState(() {});
  }

  void tick(Duration elapsed) {
    // Node widgets can handle their own ticking if needed
    // Notify cable painter to repaint
    _cableRepaintNotifier.notifyListeners();
  }

  void updatePlayback() {
    // Update the UI
    setState(() {});

    // Update the playback graph
    api.setPatch(graph: widget.patch);
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
      srcNode: start.node,
      srcEndpoint: start.endpoint,
      dstNode: end.node,
      dstEndpoint: end.endpoint,
    )) {
      _onAddCable(start, end);
    } else {
      print("Connection not supported");
    }
  }

  void removeConnectionsTo(Pin pin) {
    // Find cables to remove from the Rust patch
    var cablesToRemove = widget.patch.getCables()
        .where((cable) => 
          _pinMatchesConnection(pin, cable.source) || 
          _pinMatchesConnection(pin, cable.destination))
        .toList();
    
    for (var cable in cablesToRemove) {
      // Remove cable directly from patch
      widget.patch.removeCable(cable: cable);
      _savePatch();
      setState(() {}); // Trigger rebuild to hide removed cable
    }
  }
  
  bool _pinMatchesConnection(Pin pin, Connection connection) {
    if (pin.node.id != connection.node.id) return false;
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
            child: Listener(
              onPointerDown: (e) {
                moduleAddPosition = e.localPosition;
              },
              child: GestureDetector(
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
                                patch: widget.patch,
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



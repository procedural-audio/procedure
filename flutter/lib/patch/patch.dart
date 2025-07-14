import 'package:flutter/material.dart';
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
    return widget.patch.getNodeIds().map((nodeId) {
      return NodeEditor(
        // No key - let widgets be recreated fresh
        nodeId: nodeId,
        patch: widget.patch,
        onSave: _savePatch,
        onAddConnector: addCable,
        onRemoveConnections: removeConnectionsTo,
        onNewCableDrag: _onNewCableDrag,
        onNewCableSetStart: _onNewCableSetStart,
        onNewCableSetEnd: _onNewCableSetEnd,
        onNewCableReset: _onNewCableReset,
        onAddNewCable: _onAddNewCable,
        isSelected: selectedNodeIds.contains(nodeId),
        onToggleSelection: _toggleNodeSelection,
        onCableRepaintNeeded: () => _cableRepaintNotifier.notifyListeners(),
      );
    }).toList();
  }


  // New cable callback methods
  void _onNewCableDrag(Offset globalOffset) {
    setState(() {
      // Keep global coordinates for cursor following - don't transform to scene
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
      widget.patch.addNode(
        module: rustModule,
        position: (position.dx, position.dy),
      );
      // addNode returns the generated node ID or throws an exception if failed
      _savePatch();
      
      // Trigger rebuild to show new node
      setState(() {});
    }
  }
  
  void _onAddCable(Pin start, Pin end) {
    bool success = widget.patch.addCableByIds(
      srcNodeId: start.nodeId,
      srcEndpointId: start.endpointId,
      dstNodeId: end.nodeId,
      dstEndpointId: end.endpointId,
    );
    
    if (success) {
      _savePatch();
      setState(() {}); // Trigger rebuild to show new cable
    } else {
      print("Failed to create cable");
    }
  }
  
  void _onBatchRemoveNodes(List<int> nodeIdsToRemove) {
    for (var nodeId in nodeIdsToRemove) {
      widget.patch.removeNodeById(nodeId: nodeId);
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
  

  void removeNode(int nodeId) {
    widget.patch.removeNodeById(nodeId: nodeId);
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
    // TODO: Update connection validation to use node IDs
    // For now, skip validation and try to add cable
    _onAddCable(start, end);
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
    if (pin.nodeId != connection.node.id) return false;
    
    // Get the endpoint from the pin's IDs
    var endpoint = pin.isInput 
        ? widget.patch.getNodeInput(nodeId: pin.nodeId, endpointId: pin.endpointId)
        : widget.patch.getNodeOutput(nodeId: pin.nodeId, endpointId: pin.endpointId);
    
    if (endpoint == null) return false;
    
    return endpoint.type == connection.endpoint.type && 
           endpoint.annotation == connection.endpoint.annotation;
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
  
  void _toggleNodeSelection(int nodeId) {
    setState(() {
      if (selectedNodeIds.contains(nodeId)) {
        selectedNodeIds.remove(nodeId);
      } else {
        selectedNodeIds.add(nodeId);
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

              if (selectedNodeIds.isNotEmpty) {
                setState(() {
                  selectedNodeIds = [];
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



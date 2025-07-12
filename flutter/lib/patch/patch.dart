import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/node.dart' as rust_node;
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/patch/module.dart';
import 'package:metasampler/patch/patch_canvas.dart';

import 'dart:async';
import 'dart:io';

import '../preset/info.dart';
import 'pin.dart';
import '../plugin/plugin.dart';
import 'connector.dart';
import 'node.dart';
import 'right_click.dart';

import '../bindings/api/graph.dart' as api;

/* LIBRARY */

extension FileExtention on FileSystemEntity {
  String get name {
    return path.split("/").last;
  }
}

// Callback types
typedef NodeCallback = void Function(Module module, Offset position);
typedef ConnectorCallback = void Function(Pin start, Pin end);
typedef NodeRemoveCallback = void Function(NodeEditor node);
typedef NodeMoveCallback = void Function(NodeEditor node, Offset oldPosition, Offset newPosition);
typedef ConnectorRemoveCallback = void Function(Connector connector);
typedef BatchNodeRemoveCallback = void Function(List<NodeEditor> nodes);

// Patch data model wrapper around Rust Patch
class Patch {
  final rust_patch.Patch rustPatch;
  final PresetInfo info;
  final List<NodeEditor> nodes;
  final List<Connector> connectors;

  Patch({
    required this.rustPatch,
    required this.info,
    this.nodes = const [],
    this.connectors = const [],
  });

  static Future<Patch?> load(PresetInfo info, List<Plugin> plugins, {
    NewConnector? newConnector,
    void Function(Offset)? onNewConnectorDrag,
    void Function(Pin)? onNewConnectorSetStart,
    void Function(Pin?)? onNewConnectorSetEnd,
    VoidCallback? onNewConnectorReset,
    VoidCallback? onAddNewConnector,
  }) async {
    if (!await info.patchFile.exists()) {
      return null;
    }

    var contents = await info.patchFile.readAsString();
    var json = jsonDecode(contents);

    // Create Rust patch instance
    var rustInfo = rust_patch.PresetInfo(
      name: info.name,
      patchFilePath: info.patchFile.path,
    );
    var rustPatch = await rust_patch.Patch.newInstance(info: rustInfo);
    
    // Load JSON into rust patch
    await rustPatch.loadFromJson(jsonStr: contents);
    
    // Create a temporary patch instance for loading
    var tempPatch = Patch(
      rustPatch: rustPatch,
      info: info,
    );

    // Load nodes
    Map<int, NodeEditor> nodeMap = {};
    List<NodeEditor> nodes = [];
    if (json["nodes"] != null) {
      for (var nodeData in json["nodes"]) {
        try {
          var module = Module.fromState(nodeData["module"]);
          if (module != null) {
            var position = Offset(
              nodeData["position"]["x"]?.toDouble() ?? 0.0,
              nodeData["position"]["y"]?.toDouble() ?? 0.0,
            );
            
            var node = NodeEditor(
              module: module,
              onAddConnector: (start, end) {}, // Will be set by PatchEditor
              onRemoveConnections: (pin) {}, // Will be set by PatchEditor
              position: position,
              newConnector: newConnector ?? NewConnector(),
              onNewConnectorDrag: onNewConnectorDrag ?? (offset) {},
              onNewConnectorSetStart: onNewConnectorSetStart ?? (pin) {},
              onNewConnectorSetEnd: onNewConnectorSetEnd ?? (pin) {},
              onNewConnectorReset: onNewConnectorReset ?? () {},
              onAddNewConnector: onAddNewConnector ?? () {},
            );
            
            // Store original ID for connector reconstruction
            var originalId = nodeData["id"] ?? 0;
            nodeMap[originalId] = node;
            nodes.add(node);
          }
        } catch (e) {
          print("Failed to load node: $e");
        }
      }
    }

    // Load connectors
    List<Connector> connectors = [];
    if (json["connectors"] != null) {
      for (var connectorData in json["connectors"]) {
        try {
          var startNodeId = connectorData["startNodeId"];
          var endNodeId = connectorData["endNodeId"];
          var startNode = nodeMap[startNodeId];
          var endNode = nodeMap[endNodeId];
          
          if (startNode != null && endNode != null) {
            // Find matching endpoints by type and annotation
            Pin? startPin = _findPinByEndpoint(
              startNode, 
              connectorData["startEndpointType"], 
              connectorData["startEndpointAnnotation"]
            );
            Pin? endPin = _findPinByEndpoint(
              endNode, 
              connectorData["endEndpointType"], 
              connectorData["endEndpointAnnotation"]
            );
            
            if (startPin != null && endPin != null) {
              var connector = Connector(
                start: startPin,
                end: endPin,
                patch: tempPatch,
              );
              connectors.add(connector);
            }
          }
        } catch (e) {
          print("Failed to load connector: $e");
        }
      }
    }

    return Patch(
      rustPatch: rustPatch,
      info: info,
      nodes: nodes,
      connectors: connectors,
    );
  }

  static Pin? _findPinByEndpoint(NodeEditor node, String type, String annotation) {
    for (var pin in node.pins) {
      if (pin.endpoint.type == type && pin.endpoint.annotation == annotation) {
        return pin;
      }
    }
    return null;
  }

  // Sync Flutter nodes/connectors to Rust before saving
  Future<void> _syncToRust() async {
    // Clear existing Rust nodes
    // Since nodes are stored in Flutter side with their IDs, we can clear by ID
    for (var node in nodes) {
      if (node.rawNode != null) {
        await rustPatch.removeNode(nodeId: node.rawNode!.id);
      }
    }
    
    // Add current nodes to Rust
    for (var node in nodes) {
      if (node.rawNode != null) {
        // rawNode is of type rust_node.Node, but addNode expects ArcNode from patch.dart
        await rustPatch.addNode(node: node.rawNode! as rust_patch.ArcNode);
      }
    }
    
    // Clear existing Rust connectors
    var rustConnectors = await rustPatch.getConnectors();
    for (var connector in rustConnectors) {
      await rustPatch.removeConnector(
        startNodeId: connector.start.nodeId,
        startType: connector.start.endpointType,
        endNodeId: connector.end.nodeId,
        endType: connector.end.endpointType,
      );
    }
    
    // Add current connectors to Rust
    for (var connector in connectors) {
      var rustConnector = rust_patch.Connector(
        start: rust_patch.Pin(
          nodeId: connector.start.node.rawNode?.id ?? 0,
          endpointType: connector.start.endpoint.type,
          endpointAnnotation: connector.start.endpoint.annotation,
        ),
        end: rust_patch.Pin(
          nodeId: connector.end.node.rawNode?.id ?? 0,
          endpointType: connector.end.endpoint.type,
          endpointAnnotation: connector.end.endpoint.annotation,
        ),
      );
      await rustPatch.addConnector(connector: rustConnector);
    }
  }

  Future<void> save() async {
    // Sync Flutter state to Rust
    await _syncToRust();
    
    // Save using the Rust patch
    var jsonStr = await rustPatch.saveToJson();
    
    // Write the patch file
    await info.patchFile.writeAsString(jsonStr);

    print("Saved patch file:");
    print(info.patchFile.path);
  }
}

class PatchEditor extends StatefulWidget {
  PatchEditor({
    required this.patch,
    required this.plugins,
    required this.newConnector,
    required this.onAddNode,
    required this.onRemoveNode,
    required this.onAddConnector,
    required this.onRemoveConnector,
    required this.onMoveNode,
    required this.onBatchRemoveNodes,
    required this.onUndo,
    required this.onRedo,
  }) : super(key: UniqueKey());

  final Patch patch;
  final List<Plugin> plugins;
  final NewConnector newConnector;
  
  // Callbacks
  final NodeCallback onAddNode;
  final NodeRemoveCallback onRemoveNode;
  final ConnectorCallback onAddConnector;
  final ConnectorRemoveCallback onRemoveConnector;
  final NodeMoveCallback onMoveNode;
  final BatchNodeRemoveCallback onBatchRemoveNodes;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  _PatchEditor createState() => _PatchEditor();
}

class _PatchEditor extends State<PatchEditor> with SingleTickerProviderStateMixin {
  final TransformationController controller = TransformationController();

  Offset rightClickOffset = Offset.zero;
  Offset moduleAddPosition = Offset.zero;
  bool showRightClickMenu = false;

  final focusNode = FocusNode();
  late final Ticker _ticker;
  
  // Selected nodes managed in state
  List<NodeEditor> selectedNodes = [];

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(tick);
    _ticker.start();
  }

  @override
  void dispose() {
    controller.dispose();
    _ticker.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void removeNode(NodeEditor node) {
    widget.onRemoveNode(node);
  }

  void tick(Duration elapsed) {
    for (var node in widget.patch.nodes) {
      for (var widget in node.widgets) {
        widget.tick(elapsed);
      }
    }
  }

  void updatePlayback() {
    // Update the UI
    setState(() {});

    // Create a new graph
    var graph = api.Graph.new();

    // Add all the cables to the graph
    for (var connector in widget.patch.connectors) {
      // Skip if either node is null
      if (connector.start.node.rawNode == null ||
          connector.end.node.rawNode == null) continue;

      graph.addCable(
        srcNode: connector.start.node.rawNode!,
        srcEndpoint: connector.start.endpoint,
        dstNode: connector.end.node.rawNode!,
        dstEndpoint: connector.end.endpoint,
      );
    }

    // Add all the nodes to the graph
    for (var node in widget.patch.nodes) {
      // Skip if node is null
      if (node.rawNode == null) continue;

      graph.addNode(node: node.rawNode!);
    }

    // Update the playback graph
    api.setPatch(graph: graph);
  }

  void addModule(Module module, Offset p) {
    Offset position = Offset(roundToGrid(p.dx), roundToGrid(p.dy));
    widget.onAddNode(module, position);
  }

  void addConnector(Pin start, Pin end) {
    // Check if connection is supported
    if (api.isConnectionSupported(
      srcNode: start.node.rawNode!,
      srcEndpoint: start.endpoint,
      dstNode: end.node.rawNode!,
      dstEndpoint: end.endpoint,
    )) {
      widget.onAddConnector(start, end);
    } else {
      print("Connection not supported");
    }
  }

  void removeConnectionsTo(Pin pin) {
    // This will be handled by the patch manager
    // Find connectors to remove and call the callback
    var connectorsToRemove = widget.patch.connectors
        .where((e) => e.start == pin || e.end == pin)
        .toList();
    
    for (var connector in connectorsToRemove) {
      widget.onRemoveConnector(connector);
    }
  }
  
  // Keyboard event handlers
  void _handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent) {
      _handleUndoRedo(e);
      _handleDeleteNodes(e);
    }
  }
  
  void _handleUndoRedo(KeyDownEvent e) {
    if (HardwareKeyboard.instance.isControlPressed || 
        HardwareKeyboard.instance.isMetaPressed) {
      if (e.logicalKey == LogicalKeyboardKey.keyZ) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Redo
          widget.onRedo();
        } else {
          // Undo
          widget.onUndo();
        }
      }
    }
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
        // Offset offset = controller.toScene(details.localPosition);
        // moveTo(offset);

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
            transformationController: controller,
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
              nodes: widget.patch.nodes,
              connectors: widget.patch.connectors,
              newConnector: widget.newConnector,
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


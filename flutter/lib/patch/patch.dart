import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/bindings/api/node.dart';
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

// Patch data model
class Patch {
  final PresetInfo info;
  final List<Node> nodes;
  final List<Connector> connectors;

  Patch({
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

    // Create a temporary patch instance for loading
    var tempPatch = Patch(info: info);

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

  Future<void> save() async {
    List<Map<String, dynamic>> nodeStates = [];
    List<Map<String, dynamic>> connectorStates = [];

    // Serialize nodes with ID and CMajor source
    for (var node in nodes) {
      nodeStates.add({
        "id": node.rawNode?.id ?? 0,
        "source": node.module.source,
        "position": {
          "x": node.position.value.dx,
          "y": node.position.value.dy,
        },
        "module": node.module.getState(),
      });
    }

    // Serialize connectors
    for (var connector in connectors) {
      connectorStates.add({
        "startNodeId": connector.start.node.rawNode?.id ?? 0,
        "startEndpointType": connector.start.endpoint.type,
        "startEndpointAnnotation": connector.start.endpoint.annotation,
        "endNodeId": connector.end.node.rawNode?.id ?? 0,
        "endEndpointType": connector.end.endpoint.type,
        "endEndpointAnnotation": connector.end.endpoint.annotation,
      });
    }

    var contents = jsonEncode({
      "nodes": nodeStates,
      "connectors": connectorStates
    });

    // Write the patch file
    await info.patchFile.writeAsString(contents);

    print("Saved patch file:");
    print(info.patchFile.path);
    print("Nodes: ${nodeStates.length}, Connectors: ${connectorStates.length}");
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


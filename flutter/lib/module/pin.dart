import 'package:flutter/material.dart';

import 'dart:convert';

import 'node.dart';

import '../bindings/api/endpoint.dart';
import '../patch/connector.dart';

class Pin extends StatefulWidget {
  Pin({
    required this.node,
    required this.endpoint,
    required this.isInput,
    required this.connectors,
    required this.selectedNodes,
    required this.onAddConnector,
    required this.onRemoveConnector,
  }) : super(key: UniqueKey()) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['top'].toString()) ?? 0.0;

    // Initialize the pin offset
    if (isInput) {
      offset = Offset(5, top);
    } else {
      offset = Offset(node.module.size.width - 25, top);
    }

    // Initialize the pin color
    if (endpoint.type == EndpointType.stream) {
      color = Colors.blue;
    } else if (endpoint.type == EndpointType.event) {
      color = Colors.green;
    } else if (endpoint.type == EndpointType.value) {
      color = Colors.red;
    }
  }

  final Node node;
  final Endpoint endpoint;
  final bool isInput;
  final List<Connector> connectors;
  final ValueNotifier<List<Node>> selectedNodes;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(int, int) onRemoveConnector;

  Offset offset = Offset(0, 0);
  Color color = Colors.white;

  @override
  _PinState createState() => _PinState();
}

class _PinState extends State<Pin> {
  bool hovering = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    bool connected = false;
    for (var connector in widget.connectors) {
      if (connector.start == widget || connector.end == widget) {
        connected = true;
        break;
      }
    }

    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: MouseRegion(
        onEnter: (e) {
          print("Setting new connector end");
          widget.node.patch.newConnector.setEnd(widget);
          setState(() {
            hovering = true;
          });
        },
        onExit: (e) {
          widget.node.patch.newConnector.setEnd(null);
          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onPanStart: (details) {
            dragging = true;
            if (widget.isInput) {
              widget.node.patch.newConnector.onDrag(details.localPosition);
            } else {
              widget.node.patch.newConnector.setStart(widget);
            }
          },
          onPanUpdate: (details) {
            widget.node.patch.newConnector.onDrag(details.localPosition);
          },
          onPanEnd: (details) {
            widget.node.patch.addNewConnector();
            setState(() {
              dragging = false;
            });
          },
          onPanCancel: () {
            widget.node.patch.newConnector.reset();
            setState(() {
              dragging = false;
            });
          },
          onDoubleTap: () {
            // widget.onRemoveConnector(widget.nodeId, widget.pinIndex);
          },
          child: ValueListenableBuilder<List<Node>>(
            valueListenable: widget.selectedNodes,
            builder: (context, selectedNodes, child) {
              bool selected = selectedNodes.contains(widget.node);
              return Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: hovering || dragging || connected
                      ? (selected || hovering
                          ? widget.color
                          : widget.color.withOpacity(0.5))
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.color,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

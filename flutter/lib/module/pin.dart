import 'package:flutter/material.dart';

import 'dart:convert';

import 'node.dart';

import '../patch/patch.dart';
import '../patch/connector.dart';

import '../bindings/api/endpoint.dart';

class Pin extends StatefulWidget {
  Pin({
    required this.index,
    required this.node,
    required this.endpoint,
    required this.patch,
    required this.isInput,
    required this.onAddConnector,
    required this.onRemoveConnector,
  }) : super(key: UniqueKey()) {
    var annotation = jsonDecode(endpoint.annotation);
    var top = double.tryParse(annotation['pinTop'].toString()) ?? 0.0;

    // Initialize the pin offset
    if (isInput) {
      offset = Offset(5, top);
    } else {
      offset = Offset(node.module.size.width - 25, top);
    }

    // Initialize the pin color
    endpoint.type.when(
      stream: (streamType) {
        color = Colors.blue;
      },
      event: (eventType) {
        color = Colors.green;
      },
      value: (valueType) {
        color = Colors.red;
      },
    );
  }

  int index;
  final NodeEndpoint endpoint;
  final Node node;
  final Patch patch;
  final bool isInput;
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
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: MouseRegion(
        onEnter: (e) {
          // print("Setting new connector end");
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
          child: ValueListenableBuilder<List<Connector>>(
            valueListenable: widget.patch.connectors,
            builder: (context, connectors, child) {
              bool connected = false;
              for (var connector in connectors) {
                if (connector.start == widget || connector.end == widget) {
                  connected = true;
                  break;
                }
              }

              return ValueListenableBuilder<List<Node>>(
                valueListenable: widget.patch.selectedNodes,
                builder: (context, selectedNodes, child) {
                  bool is_selected = selectedNodes.contains(widget.node);

                  return Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: hovering || dragging || connected
                          ? (is_selected || hovering
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
              );
            },
          ),
        ),
      ),
    );
  }
}

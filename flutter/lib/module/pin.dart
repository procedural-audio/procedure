import 'package:flutter/material.dart';
import 'package:metasampler/patch/patch.dart';

import 'node.dart';

import '../patch/connector.dart';

enum IO { audio, midi, control, time, external }

class Pin extends StatefulWidget {
  Pin({
    required this.node,
    required this.nodeId,
    required this.pinIndex,
    required this.offset,
    required this.type,
    required this.isInput,
    required this.connectors,
    required this.selectedNodes,
    required this.onAddConnector,
    required this.onRemoveConnector,
  }) : super(key: UniqueKey());

  final Node node;
  final int nodeId;
  final int pinIndex;
  final Offset offset;
  final IO type;
  final bool isInput;
  final List<Connector> connectors;
  final ValueNotifier<List<Node>> selectedNodes;
  final void Function(Pin, Pin) onAddConnector;
  final void Function(int, int) onRemoveConnector;

  @override
  _PinState createState() => _PinState();
}

class _PinState extends State<Pin> {
  bool hovering = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    if (widget.type == IO.external) {
      return Container();
    }

    var color = Colors.white;

    if (widget.type == IO.audio) {
      color = Colors.blue;
    } else if (widget.type == IO.midi) {
      color = Colors.green;
    } else if (widget.type == IO.control) {
      color = Colors.red;
    } else if (widget.type == IO.time) {
      color = Colors.deepPurpleAccent;
    }

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
          widget.node.patch.newConnector.end = widget;

          setState(() {
            hovering = true;
          });
        },
        onExit: (e) {
          widget.node.patch.newConnector.end = null;

          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onPanStart: (details) {
            dragging = true;
            if (!widget.isInput) {
              widget.node.patch.newConnector.offset.value = Offset.zero;
            } else {
              print("Started drag on output node");
            }
          },
          onPanUpdate: (details) {
            if (!widget.isInput) {
              widget.node.patch.newConnector.start = widget;
              widget.node.patch.newConnector.offset.value =
                  details.localPosition;
              widget.node.patch.newConnector.type = widget.type;
            } else {
              // print("Updated drag on output node");
            }
          },
          onPanEnd: (details) {
            if (widget.node.patch.newConnector.start != null &&
                widget.node.patch.newConnector.end != null) {
              widget.onAddConnector(
                widget.node.patch.newConnector.start!,
                widget.node.patch.newConnector.end!,
              );
            } else {
              print("Connector has no end");
            }

            widget.node.patch.newConnector.start = null;
            widget.node.patch.newConnector.end = null;
            widget.node.patch.newConnector.offset.value = null;
            setState(() {
              dragging = false;
            });
          },
          onPanCancel: () {
            widget.node.patch.newConnector.start = null;
            widget.node.patch.newConnector.end = null;
            widget.node.patch.newConnector.offset.value = null;
            setState(() {
              dragging = false;
            });
          },
          onDoubleTap: () {
            widget.onRemoveConnector(widget.nodeId, widget.pinIndex);
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
                      ? (selected || hovering ? color : color.withOpacity(0.5))
                      : Colors.transparent,
                  border: Border.all(
                    color: color,
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

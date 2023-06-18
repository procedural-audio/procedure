import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:metasampler/views/settings.dart';

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ffi';

import '../patch.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart' as module;
import '../main.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

int Function(RawWidgetPointer) RawNodeSequencerGetNodeCount = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_node_sequencer_get_node_count")
    .asFunction();
int Function(RawWidgetPointer, int) RawNodeSequencerGetNodeX = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer, Int64)>>(
        "ffi_node_sequencer_get_node_x")
    .asFunction();
int Function(RawWidgetPointer, int) RawNodeSequencerGetNodeY = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer, Int64)>>(
        "ffi_node_sequencer_get_node_y")
    .asFunction();
int Function(RawWidgetPointer, int, int) RawNodeSequencerSetNodeX = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer, Int64, Int64)>>(
        "ffi_node_sequencer_set_node_x")
    .asFunction();
int Function(RawWidgetPointer, int, int) RawNodeSequencerSetNodeY = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer, Int64, Int64)>>(
        "ffi_node_sequencer_set_node_y")
    .asFunction();

void Function(RawWidgetPointer, int, int) RawNodeSequencerAddNode = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64, Int64)>>(
        "ffi_node_sequencer_add_node")
    .asFunction();

/*
 - Color nodes by velocity
 - Limit adding overlapping nodes
 - Add arrows between nodes
 - Show popup menu editor
*/

const double spacing = 50.0;

class NodeSequencerWidget extends ModuleWidget {
  NodeSequencerWidget(module.Node n, module.RawNode m, RawWidget w)
      : super(n, m, w);

  var controller = TransformationController();

  ValueNotifier<ValueNotifier<NodeState>?> selected = ValueNotifier(null);

  List<Node> nodes = [];

  @override
  Widget build(BuildContext context) {
    int count = RawNodeSequencerGetNodeCount(widgetRaw.pointer);

    nodes.clear();

    for (int i = 0; i < count; i++) {
      var state = NodeState(
          index: i,
          x: RawNodeSequencerGetNodeX(widgetRaw.pointer, i),
          y: RawNodeSequencerGetNodeY(widgetRaw.pointer, i),
          notes: []);

      nodes.add(Node(selected: selected, state: ValueNotifier(state)));
    }

    return Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromRGBO(80, 80, 80, 1.0), width: 1.0)),
        child: Stack(children: [
          InteractiveViewer(
            transformationController: controller,
            child: Container(
              width: 2000,
              height: 2000,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(20, 20, 20, 1.0),
                  border: Border.all(color: Colors.black, width: 15.0)),
              child: CustomPaint(
                painter: NodeSequencerPainter(),
                child: Stack(
                    children: <Widget>[
                          GestureDetector(
                            onTapUp: (details) {
                              setState(() {
                                int x = (details.localPosition.dx / spacing)
                                    .round();
                                int y = (details.localPosition.dy / spacing)
                                    .round();

                                RawNodeSequencerAddNode(
                                    widgetRaw.pointer, x, y);
                              });
                            },
                          ),
                        ] +
                        nodes),
              ),
            ),
            minScale: 0.1,
            maxScale: 1.5,
            panEnabled: true,
            scaleEnabled: true,
            clipBehavior: Clip.hardEdge,
            constrained: false,
            onInteractionUpdate: (details) {},
          ),
          ValueListenableBuilder<ValueNotifier<NodeState>?>(
            valueListenable: selected,
            builder: (context, notifier, w) {
              List<Widget> noteWidgets = [];

              if (notifier != null) {
                for (var note in notifier.value.notes) {
                  noteWidgets.add(Container(
                    height: 25,
                    child: Text(
                      note,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ));
                }
              }

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
                right: notifier != null ? 20 : -200,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        height: 40,
                        child: const Text(
                          "Node Attributes",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                height: 40,
                                child: const Text(
                                  "Position: ",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                              child: TextField(
                                controller: TextEditingController(
                                    text: notifier != null
                                        ? notifier.value.x.round().toString()
                                        : 0.toString()),
                                onChanged: (s) {
                                  int? tempInt = int.tryParse(s);

                                  if (tempInt != null) {
                                    if (notifier != null) {
                                      notifier.value.x = tempInt;
                                    }
                                  }
                                },
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(5),
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                              child: TextField(
                                controller: TextEditingController(
                                    text: notifier != null
                                        ? notifier.value.y.round().toString()
                                        : 0.toString()),
                                keyboardType: TextInputType.number,
                                onChanged: (s) {
                                  int? tempInt = int.tryParse(s);

                                  if (tempInt != null) {
                                    if (notifier != null) {
                                      notifier.value.y = tempInt;
                                    }
                                  }
                                },
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // (X, Y) position
                      // Velocity
                      // Notes

                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          height: 40,
                          child: Text(
                            notifier != null
                                ? notifier.value.index.toString()
                                : "",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          color: const Color.fromRGBO(30, 30, 30, 1.0),
                          child: Column(
                            children: noteWidgets +
                                [
                                  Container(
                                    color: Colors.grey,
                                  )
                                ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ]));
  }
}

class NodeSequencerPainter extends CustomPainter {
  NodeSequencerPainter();

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint = Paint()
      ..color = const Color.fromRGBO(30, 30, 30, 1.0)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class NodeState {
  NodeState(
      {required this.index,
      required this.x,
      required this.y,
      required this.notes}) {}

  int index;
  int x;
  int y;
  List<String> notes;
}

class Node extends StatefulWidget {
  Node({required this.state, required this.selected});

  ValueNotifier<ValueNotifier<NodeState>?> selected;

  ValueNotifier<NodeState> state;

  @override
  State<Node> createState() => _Node();
}

class _Node extends State<Node> {
  final double radius = 12;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ValueNotifier<NodeState>?>(
      valueListenable: widget.selected,
      builder: (context, selected, w) {
        return ValueListenableBuilder<NodeState>(
          valueListenable: widget.state,
          builder: (context, state, w) {
            bool selected = false;
            if (widget.selected.value != null) {
              if (widget.selected.value!.value.index == state.index) {
                selected = true;
              }
            }

            return Positioned(
              left: state.x * spacing - radius,
              top: state.y * spacing - radius,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                    color: selected
                        ? const Color.fromRGBO(100, 100, 100, 1.0)
                        : const Color.fromRGBO(50, 50, 50, 1.0),
                    border: Border.all(color: Colors.grey, width: 2.0),
                    borderRadius: BorderRadius.circular(radius)),
                child: GestureDetector(
                  onTap: () {
                    if (widget.selected.value != null) {
                      if (widget.selected.value!.value.index == state.index) {
                        widget.selected.value = null;
                      } else {
                        widget.selected.value = widget.state;
                      }
                    } else {
                      widget.selected.value = widget.state;
                    }
                  },
                  onPanStart: (details) {},
                  onPanUpdate: (details) {},
                  onPanEnd: (details) {},
                  onPanCancel: () {},
                ),
              ),
            );
          },
        );
      },
    );
  }
}

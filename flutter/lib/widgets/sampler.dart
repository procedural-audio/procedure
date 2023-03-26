import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../common.dart';
import '../patch.dart';
import 'widget.dart';
import 'dart:ffi';
import 'dart:ui' as ui;
import '../core.dart';
import '../module.dart';
import '../main.dart';

void Function(FFIWidgetPointer, Pointer<Utf8>) ffiSampleMapperLoad = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Pointer<Utf8>)>>(
        "ffi_sample_mapper_load")
    .asFunction();
int Function(FFIWidgetPointer) ffiSampleMapperGetRegionCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_sample_mapper_get_region_count")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiSampleMapperRemoveRegion = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int32)>>(
        "ffi_sample_mapper_remove_region")
    .asFunction();
void Function(FFIWidgetPointer, int, int, double, double)
    ffiSampleMapperAddRegion = core
        .lookup<
            NativeFunction<
                Void Function(FFIWidgetPointer, Int32, Int32, Float,
                    Float)>>("ffi_sample_mapper_add_region")
        .asFunction();
int Function(FFIWidgetPointer, int) ffiSampleMapperGetRegionLowNote = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer, Int64)>>(
        "ffi_sample_mapper_get_region_low_note")
    .asFunction();
void Function(FFIWidgetPointer, int, int) ffiSampleMapperSetRegionLowNote = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Int32)>>(
        "ffi_sample_mapper_set_region_low_note")
    .asFunction();
int Function(FFIWidgetPointer, int) ffiSampleMapperGetRegionHighNote = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer, Int64)>>(
        "ffi_sample_mapper_get_region_high_note")
    .asFunction();
void Function(FFIWidgetPointer, int, int) ffiSampleMapperSetRegionHighNote =
    core
        .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Int32)>>(
            "ffi_sample_mapper_set_region_high_note")
        .asFunction();
double Function(FFIWidgetPointer, int) ffiSampleMapperGetRegionLowVelocity =
    core
        .lookup<NativeFunction<Float Function(FFIWidgetPointer, Int64)>>(
            "ffi_sample_mapper_get_region_low_velocity")
        .asFunction();
void Function(FFIWidgetPointer, int, double)
    ffiSampleMapperSetRegionLowVelocity = core
        .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Float)>>(
            "ffi_sample_mapper_set_region_low_velocity")
        .asFunction();
double Function(FFIWidgetPointer, int) ffiSampleMapperGetRegionHighVelocity =
    core
        .lookup<NativeFunction<Float Function(FFIWidgetPointer, Int64)>>(
            "ffi_sample_mapper_get_region_high_velocity")
        .asFunction();
void Function(FFIWidgetPointer, int, double)
    ffiSampleMapperSetRegionHighVelocity = core
        .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Float)>>(
            "ffi_sample_mapper_set_region_high_velocity")
        .asFunction();
int Function(FFIWidgetPointer, int) ffiSampleMapperGetRegionSampleCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer, Int64)>>(
        "ffi_sample_mapper_get_region_sample_count")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer, int, int)
    ffiSampleMapperGetRegionSamplePath = core
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(FFIWidgetPointer, Int64,
                    Int64)>>("ffi_sample_mapper_get_region_sample_path")
        .asFunction();
FFIBuffer Function(FFIWidgetPointer, int, int)
    ffiSampleMapperGetRegionSampleBufferLeft = core
        .lookup<
            NativeFunction<
                FFIBuffer Function(FFIWidgetPointer, Int64,
                    Int64)>>("ffi_sample_mapper_get_region_sample_buffer_left")
        .asFunction();
FFIBuffer Function(FFIWidgetPointer, int, int)
    ffiSampleMapperGetRegionSampleBufferRight = core
        .lookup<
            NativeFunction<
                FFIBuffer Function(FFIWidgetPointer, Int64,
                    Int64)>>("ffi_sample_mapper_get_region_sample_buffer_right")
        .asFunction();
double Function(FFIWidgetPointer, int, int)
    ffiSampleMapperGetRegionSampleBufferTimeMs = core
        .lookup<
                NativeFunction<
                    Double Function(FFIWidgetPointer, Int64, Int64)>>(
            "ffi_sample_mapper_get_region_sample_buffer_time_ms")
        .asFunction();

const double MAP_WIDTH = (108 * 7 / 12) * KEY_WIDTH;

const double KEY_WIDTH = 24;

class SampleAreaItem extends StatefulWidget {
  SampleAreaItem(this.text);

  String text;

  @override
  State<SampleAreaItem> createState() => _SampleAreaItem();
}

class _SampleAreaItem extends State<SampleAreaItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        child: Text(widget.text,
            style: const TextStyle(color: Colors.white, fontSize: 12)));
  }
}

class SampleEditorWidget extends ModuleWidget {
  SampleEditorWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(children: [
          Container(
            width: 200,
            color: Colors.grey,
          ),
          Expanded(
              child: Column(children: [
            Expanded(
                child: Container(color: const Color.fromRGBO(30, 30, 30, 1.0))),
            Expanded(
                child: Container(
              color: const Color.fromRGBO(20, 20, 20, 1.0),
            ))
          ]))
        ]),
        decoration:
            const BoxDecoration(color: Color.fromRGBO(20, 20, 20, 1.0)));
  }
}

class SampleMapperWidget extends ModuleWidget {
  SampleMapperWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {
    refreshMap();
  }

  bool loadingSample = false;

  void refreshMap() {
    sampleMaps.clear();
    samples.clear();

    int count = ffiSampleMapperGetRegionCount(widgetRaw.pointer);
    print("Count is " + count.toString());

    for (int i = 0; i < count; i++) {
      int lowNote = ffiSampleMapperGetRegionLowNote(widgetRaw.pointer, i);
      int highNote = ffiSampleMapperGetRegionHighNote(widgetRaw.pointer, i);
      double lowVelocity =
          ffiSampleMapperGetRegionLowVelocity(widgetRaw.pointer, i);
      double highVelocity =
          ffiSampleMapperGetRegionHighVelocity(widgetRaw.pointer, i);

      // print("Adding region " + lowNote.toString() + " " + highNote.toString());

      sampleMaps.add(SampleRegion(
        lowNote: lowNote,
        highNote: highNote,
        lowVelocity: lowVelocity,
        highVelocity: highVelocity,
        index: i,
        selected: selected,
        selectedSamples: selectedSamples,
        pointer: widgetRaw.pointer,
      ));
    }
  }

  void browseForSampleMap() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var path = result.files.single.path;
      if (path != null) {
        setState(() {
          loadingSample = true;
        });

        var pathRaw = path.toNativeUtf8();
        ffiSampleMapperLoad(widgetRaw.pointer, pathRaw);
        calloc.free(pathRaw);

        refreshMap();

        setState(() {
          loadingSample = false;
        });
      }
    }
  }

  void refreshSamples() {
    samples.clear();

    if (selected.value > 0) {
      int count = ffiSampleMapperGetRegionSampleCount(
          widgetRaw.pointer, selected.value);
      for (int i = 0; i < count; i++) {
        Pointer<Utf8> pathRaw = ffiSampleMapperGetRegionSamplePath(
            widgetRaw.pointer, selected.value, i);
        String path = pathRaw.toDartString();
        calloc.free(pathRaw);

        var name = path.split("/").last;

        if (name.length > 15) {
          name = name.substring(0, 9) +
              "..." +
              name.substring(name.length - 9 - 4, name.length - 4);
        }

        samples.add(SampleListItem(name, i, selectedSamples));
      }
    }
  }

  List<SampleListItem> samples = [];
  List<SampleRegion> sampleMaps = [];

  ScrollController controller = ScrollController();
  ValueNotifier<int> selected = ValueNotifier(-1);
  ValueNotifier<List<int>> selectedSamples = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event.physicalKey == PhysicalKeyboardKey.delete ||
                event.physicalKey == PhysicalKeyboardKey.backspace) {
              if (selected.value >= 0) {
                print("Removing region");
                ffiSampleMapperRemoveRegion(widgetRaw.pointer, selected.value);
                refreshMap();
                setState(() {});
              }
            }
          },
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              child: Stack(children: [
                Scrollbar(
                    thickness: 8,
                    thumbVisibility: true,
                    controller: controller,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: controller,
                        child: Container(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                            color: const Color.fromRGBO(20, 20, 20, 1.0),
                            child: Column(children: [
                              Expanded(
                                  child: Container(
                                width: MAP_WIDTH,
                                child: CustomPaint(
                                    painter: SamplerGrid(),
                                    child: Stack(
                                        children: <Widget>[
                                              GestureDetector(
                                                  onTapDown: (details) {
                                                selected.value = -1;
                                                ffiSampleMapperAddRegion(
                                                    widgetRaw.pointer,
                                                    details.localPosition.dx ~/
                                                        (KEY_WIDTH * 7 / 12),
                                                    details.localPosition.dx ~/
                                                        (KEY_WIDTH * 7 / 12),
                                                    0.0,
                                                    1.0);
                                                refreshMap();
                                                setState(() {});
                                              })
                                            ] +
                                            sampleMaps)),
                                color: const Color.fromRGBO(20, 20, 20, 1.0),
                              )),
                              SizedBox(
                                  width: MAP_WIDTH,
                                  height: 60,
                                  child: Keyboard(
                                      keyWidth: KEY_WIDTH,
                                      keyHeight: 50,
                                      keySpacing: 1,
                                      widthRatio: 2 / 3,
                                      heightRatio: 0.6,
                                      keyCount: 108,
                                      onKeyPress: (i) {},
                                      onKeyRelease: (i) {},
                                      getKeyDown: (i) {
                                        return false;
                                      }))
                            ])))),
                SampleMapTopBar(selected),
                ValueListenableBuilder<int>(
                    valueListenable: selected,
                    builder: (context, value, w) {
                      refreshSamples();

                      const double width = 180;
                      return AnimatedPositioned(
                          curve: Curves.fastLinearToSlowEaseIn,
                          duration: const Duration(milliseconds: 800),
                          top: 0,
                          bottom: 0,
                          right: value == -1 ? -width : 0,
                          child: Container(
                            width: width,
                            height: 200,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(30, 30, 30, 1.0),
                            ),
                            child: Column(children: samples),
                          ));
                    })
              ]))),
      /*Align(
          alignment: Alignment.bottomRight,
          child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(40, 40, 40, 1.0),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(5)),
              ),
              child: IconButton(
                  icon: const Icon(Icons.folder),
                  iconSize: 18,
                  color: Colors.blue,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    browseForSampleMap();
                  }))),*/
      Visibility(
          visible: loadingSample,
          child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ))))
    ]);
  }
}

class SampleMapTopBar extends StatelessWidget {
  SampleMapTopBar(this.selected);

  ValueNotifier<int> selected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: selected,
        builder: (context, value, w) {
          return AnimatedPositioned(
              curve: Curves.fastLinearToSlowEaseIn,
              top: value == -1 ? -30 : 0,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 800),
              child: Container(
                  height: 20,
                  color: const Color.fromRGBO(30, 30, 30, 1.0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: const Text(
                        "Range: D#3 - G3",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: const Text(
                        "Velocity: 1 - 127",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                        child: const Text(
                          "Velocity: 1 - 127",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ))
                  ])));
        });
  }
}

class SampleRegion extends StatefulWidget {
  SampleRegion({
    required this.lowNote,
    required this.highNote,
    required this.lowVelocity,
    required this.highVelocity,
    required this.index,
    required this.selected,
    required this.selectedSamples,
    required this.pointer,
  }) : super(key: UniqueKey());

  int lowNote;
  int highNote;
  double lowVelocity;
  double highVelocity;

  FFIWidgetPointer pointer;

  int index;
  ValueNotifier<int> selected;
  ValueNotifier<List<int>> selectedSamples;

  @override
  State<SampleRegion> createState() => _SampleRegionState();
}

class _SampleRegionState extends State<SampleRegion> {
  double x = -1.0;
  double y = -1.0;
  // double x2 = -1.0;
  // double y2 = -1.0;

  double width = -1.0;
  double height = -1.0;

  bool dragging = false;

  bool top = false;
  bool bottom = false;
  bool left = false;
  bool right = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double ratio = KEY_WIDTH * 7 / 12;

      if (x == -1.0) {
        x = widget.lowNote * ratio;
        y = widget.lowVelocity * constraints.maxHeight;
        width = (widget.highNote - widget.lowNote + 1) * ratio;
        height =
            (widget.highVelocity - widget.lowVelocity) * constraints.maxHeight;
      }

      ffiSampleMapperSetRegionLowNote(widget.pointer, widget.index, x ~/ ratio);
      ffiSampleMapperSetRegionHighNote(
          widget.pointer, widget.index, x ~/ ratio + width ~/ ratio - 1);
      ffiSampleMapperSetRegionLowVelocity(
          widget.pointer, widget.index, y / constraints.maxHeight);
      ffiSampleMapperSetRegionHighVelocity(widget.pointer, widget.index,
          y / constraints.maxHeight + (y + height) / constraints.maxHeight);

      return Stack(children: [
        dragging || left // Left line
            ? Positioned(
                left: x - (x % ratio),
                top: 0,
                child: Container(
                  width: 1,
                  height: constraints.maxHeight,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(200, 200, 200, 0.5)),
                ))
            : Container(),
        dragging || right // Right line
            ? Positioned(
                left: x - (x % ratio) + width - (width % ratio),
                top: 0,
                child: Container(
                  width: 1,
                  height: constraints.maxHeight,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(200, 200, 200, 0.5)),
                ))
            : Container(),
        ValueListenableBuilder(
            valueListenable: widget.selected,
            builder: (context, value, w) {
              return Positioned(
                  left: x - (x % ratio) - 1,
                  top: y - (y % ratio) - 1,
                  child: Container(
                      width: width - (width % ratio) + 2,
                      height: height - (height % ratio) + 2,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color.fromRGBO(200, 200, 200, 0.5),
                            width: 2.0),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        color: value == widget.index
                            ? const Color.fromRGBO(140, 180, 100, 0.5)
                            : const Color.fromRGBO(100, 140, 180, 0.5),
                      ),
                      child: Stack(children: [
                        GestureDetector(onTap: () {
                          setState(() {
                            if (value == widget.index) {
                              widget.selected.value = -1;
                              widget.selectedSamples.value = [];
                            } else {
                              widget.selected.value = widget.index;
                              widget.selectedSamples.value = [];
                            }
                          });
                        }, onPanStart: (details) {
                          setState(() {
                            dragging = true;
                          });
                        }, onPanUpdate: (details) {
                          setState(() {
                            x += details.delta.dx;
                            y += details.delta.dy;

                            if (x < 0) {
                              x = 0;
                            }

                            if (y < 0) {
                              y = 0;
                            }

                            if (x + width > constraints.maxWidth) {
                              x = constraints.maxWidth - width;
                            }

                            if (y + height > constraints.maxHeight) {
                              y = constraints.maxHeight - height;
                            }
                          });
                        }, onPanEnd: (details) {
                          setState(() {
                            dragging = false;
                          });
                        }, onPanCancel: () {
                          setState(() {
                            dragging = false;
                          });
                        }),
                        Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                                height: 2,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      y += details.delta.dy;
                                      height -= details.delta.dy;
                                    });
                                  },
                                  onPanStart: (e) {
                                    setState(() {
                                      top = true;
                                    });
                                  },
                                  onPanEnd: (e) {
                                    setState(() {
                                      top = false;
                                    });
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      top = false;
                                    });
                                  },
                                  child: const MouseRegion(
                                      cursor: SystemMouseCursors.resizeUpDown),
                                ))),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                                height: 2,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      height += details.delta.dy;
                                    });
                                  },
                                  onPanStart: (e) {
                                    setState(() {
                                      bottom = true;
                                    });
                                  },
                                  onPanEnd: (e) {
                                    setState(() {
                                      bottom = false;
                                    });
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      bottom = false;
                                    });
                                  },
                                  child: const MouseRegion(
                                      cursor: SystemMouseCursors.resizeUpDown),
                                ))),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                                width: 2,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      x += details.delta.dx;
                                      width -= details.delta.dx;
                                    });
                                  },
                                  onPanStart: (e) {
                                    setState(() {
                                      left = true;
                                    });
                                  },
                                  onPanEnd: (e) {
                                    setState(() {
                                      left = false;
                                    });
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      left = false;
                                    });
                                  },
                                  child: const MouseRegion(
                                      cursor:
                                          SystemMouseCursors.resizeLeftRight),
                                ))),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                                width: 2,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      width += details.delta.dx;
                                    });
                                  },
                                  onPanStart: (e) {
                                    setState(() {
                                      right = true;
                                    });
                                  },
                                  onPanEnd: (e) {
                                    setState(() {
                                      right = false;
                                    });
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      right = false;
                                    });
                                  },
                                  child: const MouseRegion(
                                      cursor:
                                          SystemMouseCursors.resizeLeftRight),
                                )))
                      ])));
            })
      ]);
    });
  }
}

class SamplerGrid extends CustomPainter {
  final int count = 108;

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..color = const Color.fromRGBO(30, 30, 30, 1.0)
      ..strokeWidth = 1.0;

    Paint paint2 = Paint()
      ..color = const Color.fromRGBO(45, 45, 45, 1.0)
      ..strokeWidth = 1.0;

    double x = 0.0;
    for (int num = 0; num < count; num++) {
      if (num % 12 == 0) {
        canvas.drawLine(Offset(x, 0.0), Offset(x, size.height), paint2);
      } else {
        canvas.drawLine(Offset(x, 0.0), Offset(x, size.height), paint);
      }
      x += KEY_WIDTH * 7 / 12;
    }

    x = 0.0;
    for (int num = 0; num < count; num++) {
      if (num % 12 == 0) {
        TextSpan span = TextSpan(
            style: const TextStyle(
                color: Color.fromRGBO(80, 80, 80, 1.0), fontSize: 10),
            text: "C" + (x / KEY_WIDTH ~/ 7).toString());
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + 2.0, 2.0));
      }
      x += KEY_WIDTH * 7 / 12;
    }

    for (double y = 0.0; y < size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0.0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class SampleListItem extends StatelessWidget {
  SampleListItem(this.text, this.index, this.selectedSamples);

  String text;
  int index;
  ValueNotifier<List<int>> selectedSamples;

  @override
  Widget build(BuildContext context) {
    return Draggable(
        feedback: Container(
          height: 30,
          width: 180,
          padding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
          alignment: Alignment.centerLeft,
          child: Row(children: [
            Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  decoration: TextDecoration.none),
            ),
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    Icon(Icons.drag_indicator, size: 14, color: Colors.white),
              ),
            )
          ]),
          decoration:
              const BoxDecoration(color: Color.fromRGBO(30, 30, 30, 1.0)),
        ),
        childWhenDragging: Container(),
        data: text,
        child: ValueListenableBuilder<List<int>>(
            valueListenable: selectedSamples,
            builder: (context, value, w) {
              return GestureDetector(
                  child: Container(
                    height: 30,
                    width: 180,
                    padding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      Text(
                        text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.none),
                      ),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.drag_indicator,
                              size: 14, color: Colors.white),
                        ),
                      )
                    ]),
                    decoration: BoxDecoration(
                        color: selectedSamples.value.contains(index)
                            ? const Color.fromRGBO(50, 50, 50, 1.0)
                            : const Color.fromRGBO(30, 30, 30, 1.0)),
                  ),
                  onTap: () {
                    if (!selectedSamples.value.contains(index)) {
                      selectedSamples.value.add(index);
                    } else {
                      selectedSamples.value.remove(index);
                    }

                    selectedSamples.notifyListeners();
                  });
            }));
  }
}

/*class Keyboard extends StatefulWidget {
  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard> {
  @override
  Widget build(BuildContext context) {
    const double KEY_SPACING = 1.0;
    const double KEY_HEIGHT = 40;

    return Padding(
        padding: const EdgeInsets.all(0),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(builder: (context, constraints) {
            List<Widget> whiteKeys = [];
            List<Widget> blackKeys = [];

            double x = 0.0;
            for (int i = 1; i < 88; i++) {
              int j = i % 12;
              if (j == 1 || j == 3 || j == 6 || j == 8 || j == 10) {
                blackKeys.add(Positioned(
                    left: x + KEY_WIDTH * 4 / 6,
                    top: 0,
                    child: KeyWidget(
                      color: Colors.black,
                      pressed: false,
                      width: KEY_WIDTH * 2 / 3,
                      spacing: KEY_SPACING,
                      height: KEY_HEIGHT * 2 / 3,
                    )));
              } else {
                whiteKeys.add(Positioned(
                    left: x,
                    top: 0,
                    child: KeyWidget(
                      color: Colors.white,
                      pressed: false,
                      width: KEY_WIDTH,
                      spacing: KEY_SPACING,
                      height: KEY_HEIGHT,
                    )));

                x += KEY_WIDTH;
              }
            }

            return Stack(
              children: whiteKeys + blackKeys,
            );
          }),
        ));
  }
}

class KeyWidget extends StatefulWidget {
  KeyWidget(
      {required this.color,
      required this.pressed,
      required this.width,
      required this.spacing,
      required this.height});

  Color color;
  bool pressed;
  double width;
  double spacing;
  double height;

  @override
  State<KeyWidget> createState() => _KeyState();
}

class _KeyState extends State<KeyWidget> {
  int pressed = -1;

  @override
  Widget build(BuildContext context) {
    if (pressed == -1) {
      if (widget.pressed) {
        pressed = 1;
      } else {
        pressed = 0;
      }
    }

    return Padding(
        padding: EdgeInsets.all(widget.spacing),
        child: Listener(
          onPointerDown: (details) {
            setState(() {
              pressed = 1;
            });
          },
          onPointerUp: (details) {
            setState(() {
              pressed = 0;
            });
          },
          onPointerCancel: (details) {
            setState(() {
              pressed = 0;
            });
          },
          child: Container(
            width: widget.width - widget.spacing * 2,
            height: widget.height,
            decoration: BoxDecoration(
                color:
                    pressed == 0 ? widget.color : widget.color.withAlpha(100),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(0), bottom: Radius.circular(3))),
          ),
        ));
  }
}*/

          /*Visibility(
              visible: loadingSample,
              child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ))))*/
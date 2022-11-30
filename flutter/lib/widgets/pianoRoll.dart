import 'dart:ui' as ui;

import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../host.dart';
import 'widget.dart';

int Function(FFIWidgetPointer) ffiNotesTrackGetNoteCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_notes_track_get_note_count")
    .asFunction();

double Function(FFIWidgetPointer, int) ffiNotesTrackGetNoteStart = core
    .lookup<NativeFunction<Double Function(FFIWidgetPointer, Int64)>>(
        "ffi_notes_track_get_note_start")
    .asFunction();
double Function(FFIWidgetPointer, int) ffiNotesTrackGetNoteLength = core
    .lookup<NativeFunction<Double Function(FFIWidgetPointer, Int64)>>(
        "ffi_notes_track_get_note_length")
    .asFunction();
int Function(FFIWidgetPointer, int) ffiNotesTrackGetNoteNum = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer, Int64)>>(
        "ffi_notes_track_get_note_num")
    .asFunction();

void Function(FFIWidgetPointer, int, double) ffiNotesTrackSetNoteStart = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Double)>>(
        "ffi_notes_track_set_note_start")
    .asFunction();
void Function(FFIWidgetPointer, int, double) ffiNotesTrackSetNoteLength = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Double)>>(
        "ffi_notes_track_set_note_length")
    .asFunction();
void Function(FFIWidgetPointer, int, int) ffiNotesTrackSetNoteNum = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Int32)>>(
        "ffi_notes_track_set_note_num")
    .asFunction();

void Function(FFIWidgetPointer, double, double, int) ffiNotesTrackAddNote = core
    .lookup<
        NativeFunction<
            Void Function(FFIWidgetPointer, Double, Double,
                Int32)>>("ffi_notes_track_add_note")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiNotesTrackRemoveNote = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64)>>(
        "ffi_notes_track_remove_note")
    .asFunction();

int Function(FFIWidgetPointer) ffiNotesTrackGetBeats = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_notes_track_get_beats")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiNotesTrackSetBeats = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64)>>(
        "ffi_notes_track_set_beats")
    .asFunction();

double Function(FFIWidgetPointer) ffiNotesTrackGetBeat = core
    .lookup<NativeFunction<Double Function(FFIWidgetPointer)>>(
        "ffi_notes_track_get_beat")
    .asFunction();

/*

Design
 - Highlight and label current row and column
 - Buttons to choose note length to add
 - Change note length
 - Zoom horizontal and vertical
 - When cliking or dragging notes, show pitch, velocity, and beat
 - Show current pitch/beat while hovering
 - Single slider with two ends to adjust possible note range and vertical zoom
 - Tap selects one at a time
 - Can resize module
 - Test note generation with oscillator
 - Movable location arrow thing
 - Measure numbers
 - Fix quantization to use nearest instead of lowest
 - Drag notes as a group

*/

const double BEAT_WIDTH = 40;
const double STEP_HEIGHT = 20;
const int STEP_COUNT = 127;
const int MEASURE_BEATS = 4;

class PianoRollValues {
  List<int> selected = [];
}

class PianoRollWidget extends ModuleWidget {
  PianoRollWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  double startSelectX = 0.0;
  double startSelectY = 0.0;
  double currentSelectX = 0.0;
  double currentSelectY = 0.0;

  ValueNotifier<PianoRollValues> values = ValueNotifier(PianoRollValues());

  ValueNotifier<bool> draggingNote = ValueNotifier(false);
  ValueNotifier<double> beat = ValueNotifier(0.0);

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();
  final FocusNode focusNode = FocusNode();

  List<NoteWidget> notes = [];

  @override
  void tick() {
    beat.value = ffiNotesTrackGetBeat(widgetRaw.pointer);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);

    int beats = ffiNotesTrackGetBeats(widgetRaw.pointer);
    int count = ffiNotesTrackGetNoteCount(widgetRaw.pointer);

    for (int i = notes.length; i < count; i++) {
      notes.add(NoteWidget(
        index: notes.length,
        start: ffiNotesTrackGetNoteStart(widgetRaw.pointer, i),
        length: ffiNotesTrackGetNoteLength(widgetRaw.pointer, i),
        num: ffiNotesTrackGetNoteNum(widgetRaw.pointer, i),
        values: values,
        widgetRaw: widgetRaw,
      ));
    }

    /* Group select notes */
    if (currentSelectX != 0.0) {
      values.value.selected.clear();

      int count = ffiNotesTrackGetNoteCount(widgetRaw.pointer);

      for (int i = 0; i < count; i++) {
        double start = ffiNotesTrackGetNoteStart(widgetRaw.pointer, i);
        double length = ffiNotesTrackGetNoteLength(widgetRaw.pointer, i);
        int num = ffiNotesTrackGetNoteNum(widgetRaw.pointer, i);

        var noteRect = Rectangle.fromPoints(
            Point<double>(start * BEAT_WIDTH, (STEP_COUNT - num) * STEP_HEIGHT),
            Point<double>((start + length) * BEAT_WIDTH,
                (STEP_COUNT - num + 1) * STEP_HEIGHT));

        var selectRect = Rectangle.fromPoints(
            Point<double>(startSelectX, startSelectY),
            Point<double>(currentSelectX, currentSelectY));

        if (noteRect.intersects(selectRect)) {
          values.value.selected.add(i);
        }
      }

      values.notifyListeners();
    }

    return Stack(children: [
      ValueListenableBuilder<bool>(
        valueListenable: draggingNote,
        builder: (context, value, widgets) {
          return MouseRegion(
            cursor: value ? SystemMouseCursors.basic : SystemMouseCursors.copy,
            child: Container(
              child: KeyboardListener(
                  // autofocus: true,
                  focusNode: focusNode,
                  onKeyEvent: (e) {
                    if (e.logicalKey == LogicalKeyboardKey.delete ||
                        e.logicalKey == LogicalKeyboardKey.backspace) {
                      values.value.selected.sort((a, b) {
                        return a.compareTo(b);
                      });

                      int removed = 0;
                      for (int i in values.value.selected) {
                        ffiNotesTrackRemoveNote(widgetRaw.pointer, i - removed);
                        removed += 1;
                      }

                      values.value.selected.clear();
                      values.notifyListeners();
                      setState(() {
                        notes.clear();
                      });
                    }
                  },
                  child: Scrollbar(
                      thickness: 10,
                      thumbVisibility: true,
                      trackVisibility: true,
                      controller: horizontal,
                      child: Scrollbar(
                          thickness: 10,
                          thumbVisibility: true,
                          trackVisibility: true,
                          controller: vertical,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                              controller: horizontal,
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                  controller: vertical,
                                  child: Container(
                                      width: beats * BEAT_WIDTH,
                                      height: 127 * STEP_HEIGHT,
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 0, 10, 0),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                              CustomPaint(
                                                painter: PianoRollPainter(),
                                              ),
                                              GestureDetector(
                                                onPanStart: (details) {
                                                  setState(() {
                                                    startSelectX = details
                                                        .localPosition.dx;
                                                    startSelectY = details
                                                        .localPosition.dy;
                                                    currentSelectX = details
                                                        .localPosition.dx;
                                                    currentSelectY = details
                                                        .localPosition.dy;
                                                  });
                                                },
                                                onPanUpdate: (details) {
                                                  setState(() {
                                                    currentSelectX = details
                                                        .localPosition.dx;
                                                    currentSelectY = details
                                                        .localPosition.dy;
                                                  });
                                                },
                                                onPanEnd: (details) {
                                                  setState(() {
                                                    startSelectX = 0.0;
                                                    startSelectY = 0.0;
                                                    currentSelectX = 0.0;
                                                    currentSelectY = 0.0;
                                                  });
                                                },
                                                onTapUp: (details) {
                                                  double x =
                                                      details.localPosition.dx;
                                                  double y =
                                                      details.localPosition.dy;

                                                  double start =
                                                      x ~/ BEAT_WIDTH + 0;
                                                  int num = (STEP_COUNT -
                                                          y ~/ STEP_HEIGHT)
                                                      .clamp(0, 127);

                                                  if (start < 0) {
                                                    start = 0;
                                                  }

                                                  setState(() {
                                                    ffiNotesTrackAddNote(
                                                        widgetRaw.pointer,
                                                        start,
                                                        1.0,
                                                        num);
                                                  });

                                                  values.value.selected.clear();
                                                  values.notifyListeners();
                                                },
                                              )
                                            ] +
                                            notes +
                                            [
                                              Positioned(
                                                  left: startSelectX <
                                                          currentSelectX
                                                      ? startSelectX
                                                      : currentSelectX,
                                                  top: startSelectY <
                                                          currentSelectY
                                                      ? startSelectY
                                                      : currentSelectY,
                                                  child: Container(
                                                    width: startSelectX >
                                                            currentSelectX
                                                        ? startSelectX -
                                                            currentSelectX
                                                        : currentSelectX -
                                                            startSelectX,
                                                    height: startSelectY >
                                                            currentSelectY
                                                        ? startSelectY -
                                                            currentSelectY
                                                        : currentSelectY -
                                                            startSelectY,
                                                    decoration: BoxDecoration(
                                                        color: Colors
                                                            .blue.shade200
                                                            .withAlpha(50),
                                                        border: Border.all(
                                                            color: Colors.white
                                                                .withAlpha(50),
                                                            width: 2.0)),
                                                  )),
                                              ValueListenableBuilder<double>(
                                                  valueListenable: beat,
                                                  builder:
                                                      (context, value, parent) {
                                                    return Positioned(
                                                      left: value * BEAT_WIDTH,
                                                      child: Container(
                                                        width: 1.0,
                                                        height:
                                                            127 * STEP_HEIGHT,
                                                        decoration:
                                                            const BoxDecoration(
                                                                color: Colors
                                                                    .grey),
                                                      ),
                                                    );
                                                  })
                                            ],
                                      ))))))),
              decoration:
                  const BoxDecoration(color: Color.fromARGB(255, 30, 30, 30)),
            ),
          );
        },
      ),
    ]);
  }
}

class NoteWidget extends StatefulWidget {
  NoteWidget(
      {required this.index,
      required this.start,
      required this.length,
      required this.num,
      required this.values,
      required this.widgetRaw})
      : super(key: UniqueKey());

  int index;
  double start;
  double length;
  int num;

  FFIWidget widgetRaw;

  ValueNotifier<PianoRollValues> values;

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  double x = 0.0;
  double y = 0.0;
  double width = 0.0;

  @override
  void initState() {
    super.initState();
    x = widget.start * BEAT_WIDTH;
    y = (STEP_COUNT - widget.num) * STEP_HEIGHT;
    width = widget.length * BEAT_WIDTH;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PianoRollValues>(
        valueListenable: widget.values,
        builder: (context, value, widgets) {
          bool selected = widget.values.value.selected.contains(widget.index);

          return Positioned(
              left: x,
              top: (y ~/ STEP_HEIGHT) * STEP_HEIGHT,
              child: Container(
                  width: width,
                  height: STEP_HEIGHT,
                  decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(2),
                          child: selected
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(5)),
                                )
                              : null,
                        ),
                        GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              if (widget.values.value.selected
                                  .contains(widget.index)) {
                                widget.values.value.selected.clear();
                                widget.values.notifyListeners();
                              } else {
                                widget.values.value.selected.clear();
                                widget.values.value.selected.add(widget.index);
                                widget.values.notifyListeners();
                              }
                            });
                          },
                          onPanStart: (details) {
                            if (!widget.values.value.selected
                                .contains(widget.index)) {
                              widget.values.value.selected.clear();
                              widget.values.value.selected.add(widget.index);
                              widget.values.notifyListeners();
                            }
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              x += details.delta.dx;
                              y += details.delta.dy;

                              if (x < 0) {
                                x = 0;
                              }

                              y = y.clamp(0, 127 * STEP_HEIGHT);
                            });

                            ffiNotesTrackSetNoteStart(widget.widgetRaw.pointer,
                                widget.index, x / BEAT_WIDTH);
                            ffiNotesTrackSetNoteLength(widget.widgetRaw.pointer,
                                widget.index, width / BEAT_WIDTH);
                            ffiNotesTrackSetNoteNum(widget.widgetRaw.pointer,
                                widget.index, y ~/ STEP_HEIGHT);
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 10,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    width += details.delta.dx;

                                    ffiNotesTrackSetNoteLength(
                                        widget.widgetRaw.pointer,
                                        widget.index,
                                        width / BEAT_WIDTH);
                                  });
                                },
                              ),
                            ),
                            decoration: BoxDecoration(
                                color: Colors.black.withAlpha(50),
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(5))),
                          ),
                        )
                      ],
                    ),
                  )));
        });
  }
}

class PianoRollPainter extends CustomPainter {
  PianoRollPainter();

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint1 = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(10, 10, 10, 1.0);

    Paint paint2 = Paint()
      ..strokeWidth = STEP_HEIGHT
      ..color = const Color.fromRGBO(20, 20, 20, 1.0);

    Paint paint3 = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(100, 100, 100, 1.0);

    int n = 1;

    for (int y = size.height.toInt(); y > 0; y -= STEP_HEIGHT.toInt()) {
      if (n != 12) {
        canvas.drawLine(
            Offset(0, y + 0.0), Offset(size.width, y + 0.0), paint1);
      } else {
        canvas.drawLine(
            Offset(0, y + 0.0), Offset(size.width, y + 0.0), paint3);
      }

      if (n == 2 || n == 4 || n == 7 || n == 9 || n == 11) {
        canvas.drawRect(
            Rect.fromLTWH(0, y + 0.0, size.width, STEP_HEIGHT), paint2);
      }

      if (n < 12) {
        n += 1;
      } else {
        n = 1;
      }
    }

    Paint paint4 = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(60, 60, 60, 1.0);

    Paint paint5 = Paint()
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(40, 40, 40, 1.0);

    int beat = 0;

    for (int x = 0; x < size.width; x += BEAT_WIDTH.toInt()) {
      if (beat % MEASURE_BEATS == 0) {
        canvas.drawLine(
            Offset(x + 0.0, 0), Offset(x + 0.0, size.height), paint4);
      } else {
        canvas.drawLine(
            Offset(x + 0.0, 0), Offset(x + 0.0, size.height), paint5);
      }

      beat += 1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

import 'dart:ui' as ui;

import 'dart:ffi';

import 'package:flutter/material.dart';
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

const double BEAT_WIDTH = 40.0;
const double STEP_HEIGHT = 20.0;
const int STEP_COUNT = 127;

int measureBeats = 4;

class DragInfo {
  List<int> selected = [];
  Offset offset = const Offset(0, 0);
}

class PianoRollWidget extends ModuleWidget {
  PianoRollWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  final ScrollController controller = ScrollController();
  ValueNotifier<DragInfo> info = ValueNotifier(DragInfo());

  Offset panStart = const Offset(0.0, 0.0);
  bool selecting = false;

  bool clicked(Offset offset, Note note) {
    return note.left() <= offset.dx &&
        note.left() + note.width() >= offset.dx &&
        note.top() <= offset.dy &&
        note.top() + STEP_HEIGHT >= offset.dy;
  }

  @override
  Widget build(BuildContext context) {
    List<Note> notes = [];

    int count = ffiNotesTrackGetNoteCount(widgetRaw.pointer);

    for (int i = notes.length; i < count; i++) {
      notes.add(Note(
          index: i,
          start: ffiNotesTrackGetNoteStart(widgetRaw.pointer, i),
          length: ffiNotesTrackGetNoteLength(widgetRaw.pointer, i),
          num: ffiNotesTrackGetNoteNum(widgetRaw.pointer, i),
          info: info));
    }

    print("Notes length is " +
        notes.length.toString() +
        ". Selected " +
        info.value.selected.length.toString());

    return Stack(
      // Over/behind scroll view stack
      children: [
        Container(
          child: Scrollbar(
              isAlwaysShown: true,
              thickness: 10,
              trackVisibility: true,
              controller: controller,
              child: SingleChildScrollView(
                  controller: controller,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      height: 2000,
                      child: Stack(
                        // Scroll view stack
                        fit: StackFit.expand,
                        children: <Widget>[
                              CustomPaint(
                                painter: PianoRollPainter(
                                  beatCount: 4,
                                ),
                              ),
                            ] +
                            notes +
                            [
                              GestureDetector(
                                onTapDown: (e) {
                                  double x = e.localPosition.dx;
                                  double y = e.localPosition.dy;

                                  bool select = false;

                                  // Select note
                                  for (Note note in notes.reversed) {
                                    if (clicked(e.localPosition, note)) {
                                      if (info.value.selected
                                          .contains(note.index)) {
                                        info.value.selected.remove(note.index);
                                      } else {
                                        info.value.selected.clear();
                                        info.value.selected.add(note.index);
                                      }

                                      select = true;
                                      break;
                                    }
                                  }

                                  // Add note
                                  if (!select) {
                                    double start = x / BEAT_WIDTH;
                                    double length = 1;
                                    int num = STEP_COUNT - y ~/ STEP_HEIGHT;

                                    ffiNotesTrackAddNote(
                                        widgetRaw.pointer, start, length, num);
                                  }

                                  setState(() {});
                                },
                                onPanStart: (e) {
                                  selecting = true;

                                  for (Note note in notes.reversed) {
                                    if (clicked(e.localPosition, note)) {
                                      if (!info.value.selected
                                          .contains(note.index)) {
                                        info.value.selected.clear();
                                        info.value.selected.add(note.index);
                                        selecting = false;
                                      }

                                      break;
                                    }
                                  }

                                  setState(() {});
                                },
                                onPanUpdate: (e) {
                                  if (selecting) {
                                    print("Selecting");
                                  } else {
                                    for (Note note in notes) {
                                      if (info.value.selected
                                          .contains(note.index)) {
                                        ffiNotesTrackSetNoteStart(
                                            widgetRaw.pointer,
                                            note.index,
                                            note.start +
                                                e.delta.dx / BEAT_WIDTH);
                                        //ffiNotesTrackSetNoteNum();
                                      }
                                    }

                                    setState(() {});
                                  }
                                },
                              )
                            ],
                      )))),
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 30, 30, 30)),
        ),
      ],
    );

    /*return Stack(children: [
      ValueListenableBuilder<bool>(
        valueListenable: draggingNote,
        builder: (context, value, widgets) {
          return MouseRegion(
            cursor: value ? SystemMouseCursors.basic : SystemMouseCursors.copy,
            child: Container(
              child: Scrollbar(
                  isAlwaysShown: true,
                  thickness: 10,
                  trackVisibility: true,
                  controller: controller,
                  child: SingleChildScrollView(
                      controller: controller,
                      child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          height: 2000,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                                  CustomPaint(
                                    painter: PianoRollPainter(
                                      beatCount: beatCount,
                                    ),
                                  ),
                                  GestureDetector(
                                    onPanStart: (details) {
                                      setState(() {
                                        startDragX = details.localPosition.dx;
                                        startDragY = details.localPosition.dx;
                                        currentDragX = details.localPosition.dy;
                                        currentDragY = details.localPosition.dy;
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      setState(() {
                                        currentDragX = details.localPosition.dx;
                                        currentDragY = details.localPosition.dy;
                                      });
                                    },
                                    onPanEnd: (details) {
                                      setState(() {
                                        startDragX = 0.0;
                                        startDragY = 0.0;
                                        currentDragX = 0.0;
                                        currentDragY = 0.0;
                                      });
                                    },
                                    onTapUp: (details) {
                                      double start = details.localPosition.dx / BEAT_WIDTH;
                                      double length = 1.0;
                                      int num = STEP_COUNT - (details.localPosition.dy ~/ STEP_HEIGHT);

                                      ffiNotesTrackAddNote(
                                        widgetRaw.pointer,
                                        start,
                                        length,
                                        num
                                      );

                                      setState(() { });

                                      /*setState(() {
                                        for (var note in notes) {
                                          if (note.values.value.selected) {
                                            note.values.value.selected = false;
                                            note.values.notifyListeners();
                                          }
                                        }

                                        selectedNotes.value = 0;

                                        notes.add(NoteWidget(
                                          values:
                                              ValueNotifier(PianoRollValues()),
                                          dragginNote: draggingNote,
                                          selectedNotes: selectedNotes,
                                        ));
                                      });*/
                                    },
                                  )
                                ] +
                                notes +
                                [
                                  GestureDetector(
                                    onPanDown: (e) {

                                    },
                                    onPanUpdate: (e) {

                                    },
                                    onPanEnd: (e) {

                                    },
                                  ),
                                  Positioned(
                                      left: startDragX < currentDragX
                                          ? startDragX
                                          : currentDragX,
                                      top: startDragY < currentDragY
                                          ? startDragY
                                          : currentDragY,
                                      child: Container(
                                        width: startDragX > currentDragX
                                            ? startDragX - currentDragX
                                            : currentDragX - startDragX,
                                        height: startDragY > currentDragY
                                            ? startDragY - currentDragY
                                            : currentDragY - startDragY,
                                        decoration: BoxDecoration(
                                            color: Colors.blue.shade200
                                                .withAlpha(50),
                                            border: Border.all(
                                                color:
                                                    Colors.white.withAlpha(50),
                                                width: 2.0)),
                                      ))
                                ],
                          )))),
              decoration:
                  const BoxDecoration(color: Color.fromARGB(255, 30, 30, 30)),
            ),
          );
        },
      ),
      ValueListenableBuilder<int>(
        valueListenable: selectedNotes,
        builder: (context, value, widgets) {
          return Align(
            alignment: Alignment.topLeft,
            child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  value > 0 ? "Selected: " + value.toString() : "",
                  style: TextStyle(
                      color: Colors.white.withAlpha(100), fontSize: 16),
                )),
          );
        },
      )
    ]);*/
  }
}

class Note extends StatelessWidget {
  Note(
      {required this.index,
      required this.start,
      required this.length,
      required this.num,
      required this.info})
      : super(key: UniqueKey());

  int index;
  double start;
  double length;
  int num;
  ValueNotifier<DragInfo> info;

  double left() {
    return start * BEAT_WIDTH;
  }

  double top() {
    return (STEP_COUNT - num).toDouble() * STEP_HEIGHT;
  }

  double width() {
    return length * BEAT_WIDTH;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DragInfo>(
        valueListenable: info,
        builder: (context, value, w) {
          return Positioned(
              left: left(),
              top: top(),
              child: Container(
                width: width(),
                height: STEP_HEIGHT,
                decoration: BoxDecoration(
                    color: value.selected.contains(index)
                        ? Colors.green.shade200
                        : Colors.green,
                    border: Border.all(color: Colors.green, width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(5))),
              ));
        });
  }
}

class PianoRollPainter extends CustomPainter {
  PianoRollPainter({
    required this.beatCount,
  });

  int beatCount;

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
      if (beat % beatCount == 0) {
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

/*class NoteWidget extends StatefulWidget {
  NoteWidget({
    required this.notesWidget,
    required this.noteIndex,
    required this.values,
    required this.dragginNote,
    required this.selectedNotes,
  });

  FFIWidget notesWidget;
  int noteIndex;
  ValueNotifier<bool> dragginNote;
  ValueNotifier<int> selectedNotes;

  ValueNotifier<PianoRollValues> values;

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  Color color = Colors.green;

  double dragDeltaTop = 0.0;

  @override
  Widget build(BuildContext context) {
    double start = ffiNotesTrackGetNoteStart(widget.notesWidget.pointer, widget.noteIndex);
    int num = ffiNotesTrackGetNoteNum(widget.notesWidget.pointer, widget.noteIndex);
    double length = ffiNotesTrackGetNoteLength(widget.notesWidget.pointer, widget.noteIndex);

    double left = start * BEAT_WIDTH;
    double top = (STEP_COUNT - num).toDouble() * STEP_HEIGHT;
    double width = length * BEAT_WIDTH;

    return ValueListenableBuilder<PianoRollValues>(
        valueListenable: widget.values,
        builder: (context, value, widgets) {
          return Positioned(
              left: left,
              top: top,
              child: Container(
                  width: width,
                  height: STEP_HEIGHT,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.all(Radius.circular(5))),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(2),
                          child: widget.values.value.selected
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(5)),
                                )
                              : null,
                        ),
                        /*GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              if (widget.values.value.selected) {
                                widget.selectedNotes.value =
                                    widget.selectedNotes.value - 1;
                              } else {
                                widget.selectedNotes.value =
                                    widget.selectedNotes.value + 1;
                              }

                              widget.values.value.selected =
                                  !widget.values.value.selected;
                            });
                          },
                          onPanStart: (details) {
                            widget.dragginNote.value = true;
                            widget.selectedNotes.value =
                                widget.selectedNotes.value + 1;

                            setState(() {
                              widget.values.value.selected = true;
                              dragDeltaTop = 0.0;
                              print("Starting pan");
                            });
                          },
                          onPanUpdate: (e) {
                            double deltaStart = e.delta.dx / BEAT_WIDTH;
                            dragDeltaTop += e.delta.dy;

                            ffiNotesTrackSetNoteStart(
                              widget.notesWidget.pointer,
                              widget.noteIndex,
                              start + deltaStart);

                            // int newNum = STEP_COUNT - (top + dragDeltaTop) ~/ STEP_HEIGHT;

                            print(dragDeltaTop.toString());

                            while (dragDeltaTop >= STEP_HEIGHT / 2) {
                              ffiNotesTrackSetNoteNum(
                                widget.notesWidget.pointer,
                                widget.noteIndex,
                                num - 1
                              );

                              dragDeltaTop = dragDeltaTop - STEP_HEIGHT;
                            } 
                            
                            while (dragDeltaTop <= -STEP_HEIGHT / 2) {
                              ffiNotesTrackSetNoteNum(
                                widget.notesWidget.pointer,
                                widget.noteIndex,
                                num + 1
                              );

                              dragDeltaTop = dragDeltaTop + STEP_HEIGHT;
                            }

                            setState(() {});
                          },
                          onPanEnd: (details) {
                            widget.dragginNote.value = false;
                          },
                        ),*/
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 10,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  print("Updating length");
                                  double deltaLength = details.delta.dx / BEAT_WIDTH;

                                  ffiNotesTrackSetNoteLength(
                                    widget.notesWidget.pointer,
                                    widget.noteIndex,
                                    length + deltaLength);

                                  setState(() {});
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
*/
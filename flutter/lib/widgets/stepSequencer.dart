import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../host.dart';
import 'widget.dart';

int Function(FFIWidgetPointer) ffiStepSequencerGetStep = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_step_sequencer_get_step")
    .asFunction();
void Function(FFIWidgetPointer, int, int) ffiStepSequencerSetSize = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64, Int64)>>(
        "ffi_step_sequencer_set_size")
    .asFunction();
bool Function(FFIWidgetPointer, int, int) ffiStepSequencerGetPad = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer, Int64, Int64)>>(
        "ffi_step_sequencer_get_pad")
    .asFunction();
void Function(FFIWidgetPointer, int, int, bool) ffiStepSequencerSetPad = core
    .lookup<
        NativeFunction<
            Void Function(FFIWidgetPointer, Int64, Int64,
                Bool)>>("ffi_step_sequencer_set_pad")
    .asFunction();
int Function(FFIWidgetPointer, int) ffiStepSequencerGetRowNoteCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer, Int64)>>(
        "ffi_step_sequencer_get_row_note_count")
    .asFunction();
int Function(FFIWidgetPointer, int, int) ffiStepSequencerGetRowNoteIndex = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer, Int64, Int64)>>(
        "ffi_step_sequencer_get_row_note_index")
    .asFunction();
void Function(FFIWidgetPointer, int, int, bool) ffiStepSequencerSetRowNote =
    core
        .lookup<
            NativeFunction<
                Void Function(FFIWidgetPointer, Int64, Int32,
                    Bool)>>("ffi_step_sequencer_set_row_note")
        .asFunction();

class StepSequencerWidget extends ModuleWidget {
  StepSequencerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    step = ffiStepSequencerGetStep(widgetRaw.pointer);
  }

  int rows = 8;
  int cols = 16;

  int step = 0;

  double leftWidth = 80;

  @override
  void tick() {
    int stepNew = ffiStepSequencerGetStep(widgetRaw.pointer);

    if (stepNew != step) {
      setState(() {
        step = stepNew;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      rows = constraints.maxHeight ~/ 42;
      cols = (constraints.maxWidth - leftWidth) ~/ 42;

      ffiStepSequencerSetSize(widgetRaw.pointer, cols, rows);

      List<Row> rowWidgets = [];

      for (int r = 0; r < rows; r++) {
        List<Widget> pads = [];

        for (int c = 0; c < cols; c++) {
          pads.add(SequencerPad(
            color: Colors.green,
            pressed: ffiStepSequencerGetPad(widgetRaw.pointer, c, r),
            x: c,
            y: r,
            widgetRaw: widgetRaw,
          ));
        }

        rowWidgets.add(Row(children: pads));
      }

      return Container(
          decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 20, 20, 1.0),
              borderRadius: BorderRadius.circular(10)),
          child: Stack(fit: StackFit.expand, children: [
            Padding(
                padding: EdgeInsets.fromLTRB(leftWidth, 20, 0, 0),
                child: CustomPaint(
                  painter:
                      SequencerHighlight(step: step, steps: cols, width: 42),
                )),
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Column(
                  children: rowWidgets,
                ))
          ]));
    });
  }
}

class SequencerPad extends StatefulWidget {
  SequencerPad(
      {required this.color,
      required this.pressed,
      required this.x,
      required this.y,
      required this.widgetRaw});

  Color color;
  bool pressed;
  int x;
  int y;
  FFIWidget widgetRaw;

  @override
  State<SequencerPad> createState() => _SequencerPadState();
}

class _SequencerPadState extends State<SequencerPad> {
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

    ffiStepSequencerSetPad(
        widget.widgetRaw.pointer, widget.x, widget.y, pressed == 1);

    return Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: pressed == 1 ? widget.color : widget.color.withAlpha(50),
              borderRadius: BorderRadius.circular(5)),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (pressed == 0) {
                  pressed = 1;
                } else {
                  pressed = 0;
                }
              });
            },
          ),
        ));
  }
}

class SequencerHighlight extends CustomPainter {
  SequencerHighlight(
      {required this.step, required this.steps, required this.width});

  int step;
  int steps;
  double width;

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint1 = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.grey.withAlpha(80);

    Paint paint2 = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.grey.withAlpha(50);

    canvas.drawLine(Offset(step / steps * (steps * width), 0),
        Offset(step / steps * (steps * width), size.height), paint1);

    canvas.drawLine(Offset((step + 1) / steps * (steps * width), 0),
        Offset((step + 1) / steps * (steps * width), size.height), paint1);

    canvas.drawRect(
        Rect.fromLTWH(step / steps * (steps * width), 0, width, size.height),
        paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/*class NoteSelectorButton extends StatefulWidget {
  NoteSelectorButton(
      {required this.width,
      required this.height,
      required this.row,
      required this.widgetRaw});

  double width;
  double height;
  int row;
  FFIWidget widgetRaw;

  @override
  State<NoteSelectorButton> createState() => _NoteSelectorButton();
}

class _NoteSelectorButton extends State<NoteSelectorButton> {
  List<int> notes = [];
  var controller = TextEditingController();
  OverlayEntry? entry;

  Offset location = const Offset(0, 0);

  bool hover = false;

  OverlayEntry _createEntry() {
    const double width = 250;
    const double height = 105;

    return OverlayEntry(builder: (context) {
      return GestureDetector(
          onTap: () {
            entry?.remove();
          },
          child: Container(
              // duration: const Duration(milliseconds: 300),
              color: Colors.black.withAlpha(0),
              constraints: const BoxConstraints.expand(),
              child: Stack(fit: StackFit.expand, children: [
                Positioned(
                  left: location.dx - width / 2,
                  top: location.dy - height / 2,
                  child: NoteSelector(
                    width: width,
                    height: height,
                    row: widget.row,
                    widgetRaw: widget.widgetRaw,
                  ),
                )
              ])));
    });
  }

  @override
  Widget build(BuildContext context) {
    notes.clear();

    int noteCount =
        ffiStepSequencerGetRowNoteCount(widget.widgetRaw.pointer, widget.row);

    for (int i = 0; i < noteCount; i++) {
      notes.add(ffiStepSequencerGetRowNoteIndex(
          widget.widgetRaw.pointer, widget.row, i));
    }

    String text = "";

    for (var note in notes) {
      text = text + " " + note.toString();
    }

    return MouseRegion(
        onEnter: (e) {
          setState(() {
            hover = true;
          });
        },
        onExit: (e) {
          setState(() {
            hover = false;
          });
        },
        child: GestureDetector(
            onTapDown: (e) {
              entry = _createEntry();
              location = e.globalPosition -
                  e.localPosition +
                  Offset(widget.width / 2, widget.height / 2);

              if (entry != null) {
                Overlay.of(context)?.insert(entry!);
              }
            },
            child: Container(
                width: widget.width,
                height: widget.height,
                color: const Color.fromRGBO(40, 40, 40, 1.0),
                padding: const EdgeInsets.fromLTRB(0, 5, 10, 5),
                child: Container(
                  decoration: BoxDecoration(
                      color: hover
                          ? const Color.fromRGBO(30, 30, 30, 1.0)
                          : const Color.fromRGBO(20, 20, 20, 1.0),
                      borderRadius: BorderRadius.circular(5)),
                  child: Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          decoration: ui.TextDecoration.none),
                    ),
                  ),
                ))));
  }
}

class NoteSelector extends StatefulWidget {
  NoteSelector(
      {required this.width,
      required this.height,
      required this.row,
      required this.widgetRaw});

  double width;
  double height;
  int row;
  FFIWidget widgetRaw;

  @override
  State<NoteSelector> createState() => _NoteSelector();
}

class _NoteSelector extends State<NoteSelector> {
  var controller = TextEditingController();
  OverlayEntry? entry;

  Offset location = const Offset(0, 0);
  int octave = 3;

  @override
  Widget build(BuildContext context) {
    List<int> notes = [];
    int noteCount =
        ffiStepSequencerGetRowNoteCount(widget.widgetRaw.pointer, widget.row);

    for (int i = 0; i < noteCount; i++) {
      notes.add(ffiStepSequencerGetRowNoteIndex(
          widget.widgetRaw.pointer, widget.row, i));
    }

    List<Widget> keys = [];

    for (int i = 0; i < 7; i++) {
      bool selected = false;

      int noteIndex = 0;
      if (i == 0) {
        noteIndex = 0;
      } else if (i == 1) {
        noteIndex = 2;
      } else if (i == 2) {
        noteIndex = 4;
      } else if (i == 3) {
        noteIndex = 5;
      } else if (i == 4) {
        noteIndex = 7;
      } else if (i == 5) {
        noteIndex = 9;
      } else if (i == 6) {
        noteIndex = 11;
      }

      int noteNum = 21 + octave * 12 + noteIndex;
      if (notes.contains(noteNum)) {
        selected = true;
      }

      keys.add(Positioned(
        left: i * widget.width / 7,
        child: Key(
          width: widget.width / 7,
          height: 70,
          selected: selected,
          onTap: () {
            setState(() {
              ffiStepSequencerSetRowNote(
                  widget.widgetRaw.pointer, widget.row, noteNum, !selected);
            });
          },
        ),
      ));
    }

    for (var i in [0.5, 1.5, 3.5, 4.5, 5.5]) {
      bool selected = false;

      int noteIndex = 0;
      if (i == 0.5) {
        noteIndex = 1;
      } else if (i == 1.5) {
        noteIndex = 3;
      } else if (i == 3.5) {
        noteIndex = 6;
      } else if (i == 4.5) {
        noteIndex = 8;
      } else if (i == 5.5) {
        noteIndex = 10;
      }

      int noteNum = 21 + octave * 12 + noteIndex;
      if (notes.contains(noteNum)) {
        selected = true;
      }

      keys.add(Positioned(
        left: i * widget.width / 7 + 3,
        child: Key(
          width: widget.width / 7 - 6,
          height: 40,
          selected: selected,
          onTap: () {
            setState(() {
              ffiStepSequencerSetRowNote(
                  widget.widgetRaw.pointer, widget.row, noteNum, !selected);
            });
          },
        ),
      ));
    }

    for (int i = 0; i < 8; i++) {
      bool selected = false;

      for (var num in notes) {
        int min = 21 + 12 * i;
        int max = 21 + 12 * (i + 1);

        if (num >= min && num < max) {
          selected = true;
          break;
        }
      }

      keys.add(Positioned(
        top: 72,
        left: i * widget.width / 8,
        child: GestureDetector(
          onTap: () {
            setState(() {
              octave = i;
            });
          },
          child: Container(
            width: widget.width / 8,
            height: 29,
            decoration: BoxDecoration(
                color: i == octave
                    ? const Color.fromRGBO(60, 60, 60, 1.0)
                    : const Color.fromRGBO(40, 40, 40, 1.0)),
            child: Center(
              child: Text(
                i.toString(),
                style: TextStyle(
                    color: selected ? Colors.green : Colors.grey,
                    fontSize: 10,
                    decoration: ui.TextDecoration.none),
              ),
            ),
          ),
        ),
      ));
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          border: Border.all(
              color: const Color.fromRGBO(60, 60, 60, 1.0), width: 2.0),
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 5)
          ]),
      child: Stack(
        children: keys,
      ),
    );
  }
}

class Key extends StatefulWidget {
  Key(
      {required this.width,
      required this.height,
      required this.selected,
      required this.onTap});

  double width;
  double height;
  bool selected;
  VoidCallback onTap;

  @override
  State<Key> createState() => _Key();
}

class _Key extends State<Key> {
  bool over = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (e) {
          setState(() {
            over = true;
          });
        },
        onExit: (e) {
          setState(() {
            over = false;
          });
        },
        child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                  color: widget.selected
                      ? Colors.green
                      : (over
                          ? const Color.fromRGBO(40, 40, 40, 1.0)
                          : const Color.fromRGBO(20, 20, 20, 1.0)),
                  border: Border.all(
                      color: const Color.fromRGBO(80, 80, 80, 1.0), width: 1),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(7))),
            )));
  }
}
*/
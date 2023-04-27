import 'dart:ui' as ui;

import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widget.dart';

import '../core.dart';
import '../module.dart';

int Function(RawWidgetPointer) ffiNotesTrackGetEventCount = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_notes_track_get_event_count")
    .asFunction();
int Function(RawWidgetPointer, int) ffiNotesTrackIndexGetId = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_index_get_id")
    .asFunction();
int Function(RawWidgetPointer, int) ffiNotesTrackIndexGetType = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_index_get_type")
    .asFunction();

double Function(RawWidgetPointer, int) ffiNotesTrackIdGetTime = core
    .lookup<NativeFunction<Double Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_id_get_time")
    .asFunction();
double Function(RawWidgetPointer, int) ffiNotesTrackIdGetOnTime = core
    .lookup<NativeFunction<Double Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_id_get_on_time")
    .asFunction();
double Function(RawWidgetPointer, int) ffiNotesTrackIdGetOffTime = core
    .lookup<NativeFunction<Double Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_id_get_off_time")
    .asFunction();
void Function(RawWidgetPointer, int, double) ffiNotesTrackIdSetTime = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64, Double)>>(
        "ffi_notes_track_id_set_time")
    .asFunction();
void Function(RawWidgetPointer, int, double) ffiNotesTrackIdSetOnTime = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64, Double)>>(
        "ffi_notes_track_id_set_on_time")
    .asFunction();
void Function(RawWidgetPointer, int, double) ffiNotesTrackIdSetOffTime = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64, Double)>>(
        "ffi_notes_track_id_set_off_time")
    .asFunction();
int Function(RawWidgetPointer, int) ffiNotesTrackIdGetNoteOnNum = core
    .lookup<NativeFunction<Int32 Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_id_get_note_on_num")
    .asFunction();
void Function(RawWidgetPointer, int, int) ffiNotesTrackIdSetNoteOnNum = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64, Int32)>>(
        "ffi_notes_track_id_set_note_on_num")
    .asFunction();
void Function(RawWidgetPointer, int) ffiNotesTrackIdRemoveNote = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_id_remove_note")
    .asFunction();

void Function(RawWidgetPointer, double, double, int) ffiNotesTrackAddNote = core
    .lookup<
        NativeFunction<
            Void Function(RawWidgetPointer, Double, Double,
                Int32)>>("ffi_notes_track_add_note")
    .asFunction();
int Function(RawWidgetPointer) ffiNotesTrackGetLength = core
    .lookup<NativeFunction<Int64 Function(RawWidgetPointer)>>(
        "ffi_notes_track_get_length")
    .asFunction();
void Function(RawWidgetPointer, int) ffiNotesTrackSetLength = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Int64)>>(
        "ffi_notes_track_set_length")
    .asFunction();
double Function(RawWidgetPointer) ffiNotesTrackGetBeat = core
    .lookup<NativeFunction<Double Function(RawWidgetPointer)>>(
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

const double BEAT_WIDTH = 30;
const double STEP_HEIGHT = 15;
const int STEP_COUNT = 127;
const int MEASURE_BEATS = 4;

enum NoteType { noteOn, noteOff, pitch, pressure, other }

class NoteEvent {
  NoteEvent({required this.index, required this.id, required this.type});

  int index;
  int id;
  NoteType type;
}

class PianoRollWidget extends ModuleWidget {
  PianoRollWidget(RawNode m, RawWidget w) : super(m, w);
  ValueNotifier<Rectangle?> selectedRegion = ValueNotifier(null);
  Offset selectedStart = const Offset(0.0, 0.0);

  final FocusNode focusNode = FocusNode();

  ValueNotifier<List<int>> selectedIds = ValueNotifier([]);

  ValueNotifier<bool> draggingNote = ValueNotifier(false);
  ValueNotifier<double> beat = ValueNotifier(0.0);
  ValueNotifier<Offset> zoom = ValueNotifier(const Offset(1.0, 1.0));

  List<NoteEvent> events = [];
  List<NoteWidget> noteWidgets = [];

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  @override
  void tick() {
    beat.value = ffiNotesTrackGetBeat(widgetRaw.pointer);
  }

  @override
  Widget build(BuildContext context) {
    // FocusScope.of(context).requestFocus(focusNode);

    bool updatedEvents = false;
    int beats = ffiNotesTrackGetLength(widgetRaw.pointer);
    int count = ffiNotesTrackGetEventCount(widgetRaw.pointer);

    events.clear();
    for (int i = 0; i < count; i++) {
      updatedEvents = true;

      var numType = ffiNotesTrackIndexGetType(widgetRaw.pointer, i);
      var type = NoteType.other;
      var id = ffiNotesTrackIndexGetId(widgetRaw.pointer, i);

      if (numType == 0) {
        type = NoteType.noteOn;
      } else if (numType == 1) {
        type = NoteType.noteOff;
      } else if (numType == 2) {
        type = NoteType.pitch;
      } else if (numType == 3) {
        type = NoteType.pressure;
      } else {
        print("Unknown " + id.toString());
      }

      events.add(NoteEvent(index: i, id: id, type: type));
    }

    /* Update note widgets */

    if (updatedEvents) {
      noteWidgets.clear();

      for (var event in events) {
        if (event.type == NoteType.noteOn) {
          bool found = false;
          for (var event2 in events) {
            if (event.id == event2.id && event2.type == NoteType.noteOff) {
              found = true;
              noteWidgets.add(
                NoteWidget(
                  id: event.id,
                  selectedRegion: selectedRegion,
                  selectedIds: selectedIds,
                  widgetRaw: widgetRaw,
                  refreshNotes: () {
                    setState(() {
                      events.clear();
                    });
                  },
                ),
              );

              break;
            }
          }

          if (!found) {
            print("COULDN'T FIND NOTE OFF EVENT");
          }
        } else if (event.type == NoteType.pitch) {
          /*noteWidgets.add(PitchEventWidget(
            index: event.index,
            start: event.time,
            length: event.time + 1, // CHANGE THIS
            num: ffiNotesTrackIndexGetNoteOnNum(widgetRaw.pointer, event.index),
            selectedIds: selectedIds,
            widgetRaw: widgetRaw,
          ));*/
        } else if (event.type == NoteType.pressure) {}
      }
    }

    return MouseRegion(
      onEnter: (e) {
        FocusScope.of(context).requestFocus(focusNode);
      },
      child: KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (e) {
          if (e.logicalKey == LogicalKeyboardKey.delete ||
              e.logicalKey == LogicalKeyboardKey.backspace) {
            events.clear();
            noteWidgets.clear();

            for (int i in selectedIds.value) {
              ffiNotesTrackIdRemoveNote(widgetRaw.pointer, i);
            }

            selectedIds.value.clear();
            selectedIds.notifyListeners();

            setState(() {});
          }
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          child: Stack(
            children: [
              NotesScrollWidget(
                draggingNote: draggingNote,
                selectedIds: selectedIds,
                beat: beat,
                beats: beats,
                horizontal: horizontal,
                vertical: vertical,
                children: <Widget>[
                      GestureDetector(
                        onTapUp: (details) {
                          double x = details.localPosition.dx;
                          double y = details.localPosition.dy;
                          double start = x ~/ BEAT_WIDTH + 0;
                          int num =
                              (STEP_COUNT - y ~/ STEP_HEIGHT).clamp(0, 127);

                          if (start < 0) {
                            start = 0;
                          }

                          ffiNotesTrackAddNote(
                              widgetRaw.pointer, start, 2.0, num);
                          events.clear();
                          selectedIds.value.clear();
                          selectedIds.notifyListeners();

                          setState(() {});
                        },
                        onPanStart: (e) {
                          selectedStart =
                              Offset(e.localPosition.dx, e.localPosition.dy);
                          selectedRegion.value = null;

                          selectedIds.value.clear();
                          selectedIds.notifyListeners();
                        },
                        onPanUpdate: (e) {
                          double left = selectedStart.dx;
                          double width = e.localPosition.dx - left;
                          double top = selectedStart.dy;
                          double height = e.localPosition.dy - top;

                          if (width > 0) {
                            if (height > 0) {
                              selectedRegion.value =
                                  Rectangle(left, top, width, height);
                            } else {
                              selectedRegion.value = Rectangle(
                                  left,
                                  e.localPosition.dy,
                                  width,
                                  top - e.localPosition.dy);
                            }
                          } else {
                            if (height > 0) {
                              selectedRegion.value = Rectangle(
                                  e.localPosition.dx,
                                  top,
                                  left - e.localPosition.dx,
                                  height);
                            } else {
                              selectedRegion.value = Rectangle(
                                  e.localPosition.dx,
                                  e.localPosition.dy,
                                  left - e.localPosition.dx,
                                  top - e.localPosition.dy);
                            }
                          }
                        },
                        onPanEnd: (e) {
                          selectedRegion.value = null;
                        },
                        onPanCancel: () {
                          selectedRegion.value = null;
                        },
                      ),
                      TimeIndicator(beat),
                      DragRegion(selectedRegion)
                    ] +
                    noteWidgets,
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: NotesWidgetSidebar(),
              ),
              LayoutBuilder(builder: (context, constraints) {
                return Align(
                  alignment: Alignment.bottomRight,
                  child: NotesMapWidget(
                    noteWidgets,
                    horizontal,
                    vertical,
                    ui.Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class NotesWidgetSidebar extends StatefulWidget {
  NotesWidgetSidebar();

  @override
  State<StatefulWidget> createState() => _NotesWidgetSidebar();
}

class _NotesWidgetSidebar extends State<NotesWidgetSidebar> {
  bool expanded = false;
  final double width = 300.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: width,
          child: Stack(
            children: [
              AnimatedPositioned(
                left: expanded ? 0 : -width,
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastLinearToSlowEaseIn,
                child: Container(
                  width: width,
                  height: constraints.maxHeight,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(20, 20, 20, 1.0),
                  ),
                  child: Column(
                    children: [
                      /*Slider(
                          value: (widget.zoom.value.dx - 0.1) / 0.9,
                          onChanged: (v) {
                            widget.zoom.value =
                                Offset(v * 0.9 + 0.1, widget.zoom.value.dy);
                            setState(() {});
                          }),
                      Slider(
                        value: (widget.zoom.value.dy - 0.1) / 0.9,
                        onChanged: (v) {
                          widget.zoom.value =
                              Offset(widget.zoom.value.dx, v * 0.9 + 0.1);
                          setState(() {});
                        },
                      ),*/
                    ],
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(40, 40, 40, 1.0),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(5),
                  ),
                  border: Border.all(
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                    width: 2.0,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastLinearToSlowEaseIn,
                    turns: expanded ? 0.5 : 1.0,
                    child: const Icon(
                      Icons.chevron_left,
                      size: 18.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TimeIndicator extends StatelessWidget {
  TimeIndicator(this.beat);

  ValueNotifier<double> beat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: beat,
      builder: (context, value, parent) {
        return Positioned(
          left: value * BEAT_WIDTH,
          child: Container(
            width: 1.0,
            height: 127 * STEP_HEIGHT,
            decoration: const BoxDecoration(color: Colors.grey),
          ),
        );
      },
    );
  }
}

class NotesScrollWidget extends StatelessWidget {
  NotesScrollWidget({
    required this.draggingNote,
    required this.selectedIds,
    required this.beat,
    required this.beats,
    required this.children,
    required this.horizontal,
    required this.vertical,
  }) {
    /*horizontal.addListener(() {
      controller.toScene(Offset(horizontal.offset, vertical.offset));
    });

    vertical.addListener(() {
      controller.toScene(Offset(horizontal.offset, vertical.offset));
    });

    horizontal.createScrollPosition(ScrollPhysics(), ScrollContext, oldPosition)*/
  }

  List<Widget> children;

  final ScrollController horizontal;
  final ScrollController vertical;

  ValueNotifier<bool> draggingNote;
  ValueNotifier<List<int>> selectedIds;
  ValueNotifier<double> beat;
  int beats;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: draggingNote,
      builder: (context, value, widgets) {
        return ValueListenableBuilder<double>(
          valueListenable: beat,
          builder: (context, beat, child) {
            /*horizontal.animateTo(
              beat * BEAT_WIDTH * 8 / 9,
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeInOut,
            );*/

            return MouseRegion(
              cursor:
                  value ? SystemMouseCursors.basic : SystemMouseCursors.copy,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(30, 30, 30, 1.0),
                ),
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
                    notificationPredicate: (notif) => true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(0),
                      controller: horizontal,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: vertical,
                        child: CustomPaint(
                          painter: PianoRollPainter(
                            horizontal: horizontal,
                            vertical: vertical,
                          ),
                          child: SizedBox(
                            width: BEAT_WIDTH * beats,
                            height: STEP_HEIGHT * 127,
                            child: Stack(
                              fit: StackFit.expand,
                              children: children,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DragRegion extends StatelessWidget {
  DragRegion(this.selectedRegion);

  ValueNotifier<Rectangle?> selectedRegion;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Rectangle?>(
      valueListenable: selectedRegion,
      builder: (context, region, child) {
        if (region != null) {
          return Positioned(
            left: region.left.toDouble(),
            top: region.top.toDouble(),
            // right: region.right.toDouble(),
            // bottom: region.bottom.toDouble(),
            child: Container(
              width: region.width.toDouble(),
              height: region.height.toDouble(),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.25),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                border: Border.all(
                  width: 2.0,
                  color: const Color.fromRGBO(255, 255, 255, 0.5),
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class NoteWidget extends StatefulWidget {
  NoteWidget({
    required this.id,
    required this.selectedIds,
    required this.selectedRegion,
    required this.refreshNotes,
    required this.widgetRaw,
  }) : super(key: UniqueKey());

  int id;

  RawWidget widgetRaw;

  ValueNotifier<Rectangle?> selectedRegion;
  ValueNotifier<List<int>> selectedIds;
  void Function() refreshNotes;

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  @override
  void initState() {
    super.initState();
    widget.selectedRegion.addListener(onSelectRegion);
  }

  @override
  void dispose() {
    super.dispose();
    widget.selectedRegion.removeListener(onSelectRegion);
  }

  void onSelectRegion() {
    double start =
        ffiNotesTrackIdGetOnTime(widget.widgetRaw.pointer, widget.id);
    double end = ffiNotesTrackIdGetOffTime(widget.widgetRaw.pointer, widget.id);
    int num = ffiNotesTrackIdGetNoteOnNum(widget.widgetRaw.pointer, widget.id);

    double x = start * BEAT_WIDTH;
    double y = (STEP_COUNT - num) * STEP_HEIGHT;

    if (widget.selectedRegion.value != null) {
      if (widget.selectedRegion.value!.intersects(Rectangle(
          x,
          (y ~/ STEP_HEIGHT) * STEP_HEIGHT,
          (end - start) * BEAT_WIDTH,
          STEP_HEIGHT))) {
        if (!widget.selectedIds.value.contains(widget.id)) {
          widget.selectedIds.value.add(widget.id);
          setState(() {});
        }
      } else {
        if (widget.selectedIds.value.contains(widget.id)) {
          widget.selectedIds.value.remove(widget.id);
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: widget.selectedIds,
      builder: (context, selectedIds, widgets) {
        double startTime = ffiNotesTrackIdGetOnTime(
          widget.widgetRaw.pointer,
          widget.id,
        );

        double endTime = ffiNotesTrackIdGetOffTime(
          widget.widgetRaw.pointer,
          widget.id,
        );

        int num = ffiNotesTrackIdGetNoteOnNum(
          widget.widgetRaw.pointer,
          widget.id,
        );

        double x = startTime * BEAT_WIDTH;
        double y = (STEP_COUNT - num) * STEP_HEIGHT;
        double width = (endTime - startTime) * BEAT_WIDTH;
        bool selected = selectedIds.contains(widget.id);

        return Positioned(
          left: x,
          top: (y ~/ STEP_HEIGHT) * STEP_HEIGHT,
          child: Container(
            width: width,
            height: STEP_HEIGHT,
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
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
                              borderRadius: BorderRadius.circular(5),
                            ),
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        if (selectedIds.contains(widget.id)) {
                          selectedIds.remove(widget.id);
                          widget.selectedIds.notifyListeners();
                        } else {
                          selectedIds.clear();
                          selectedIds.add(widget.id);
                          widget.selectedIds.notifyListeners();
                        }
                      });
                    },
                    onPanStart: (details) {
                      if (!selectedIds.contains(widget.id)) {
                        selectedIds.clear();
                        selectedIds.add(widget.id);
                        widget.selectedIds.notifyListeners();
                      }
                    },
                    onPanUpdate: (details) {
                      double deltax = details.delta.dx;

                      x += deltax;
                      // y += details.delta.dy;

                      if (x < 0) {
                        x = 0;
                      }

                      // y = y.clamp(0, 127 * STEP_HEIGHT);
                      ffiNotesTrackIdSetOnTime(
                          widget.widgetRaw.pointer, widget.id, x / BEAT_WIDTH);
                      ffiNotesTrackIdSetOffTime(widget.widgetRaw.pointer,
                          widget.id, x / BEAT_WIDTH + width / BEAT_WIDTH);

                      bool shouldRefreshAll = false;
                      for (var id in widget.selectedIds.value) {
                        if (id == widget.id) {
                          continue;
                        } else {
                          shouldRefreshAll = true;
                        }

                        double startTime = ffiNotesTrackIdGetOnTime(
                            widget.widgetRaw.pointer, id);
                        double endTime = ffiNotesTrackIdGetOffTime(
                            widget.widgetRaw.pointer, id);
                        double x = startTime * BEAT_WIDTH;
                        double width = (endTime - startTime) * BEAT_WIDTH;

                        x += deltax;

                        ffiNotesTrackIdSetOnTime(
                            widget.widgetRaw.pointer, id, x / BEAT_WIDTH);
                        ffiNotesTrackIdSetOffTime(widget.widgetRaw.pointer, id,
                            x / BEAT_WIDTH + width / BEAT_WIDTH);
                      }

                      if (shouldRefreshAll) {
                        setState(() {});
                        widget.selectedIds.notifyListeners();
                      } else {
                        setState(() {});
                      }
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
                            double deltax = details.delta.dx;

                            /* Constrain deltax */
                            deltax = deltax.clamp(-width + 10, deltax);

                            for (var id in widget.selectedIds.value) {
                              double startTime = ffiNotesTrackIdGetOnTime(
                                widget.widgetRaw.pointer,
                                id,
                              );

                              double endTime = ffiNotesTrackIdGetOffTime(
                                widget.widgetRaw.pointer,
                                id,
                              );

                              double width = (endTime - startTime) * BEAT_WIDTH;
                              deltax = deltax.clamp(-width + 10, deltax);
                            }

                            /* Update current note */

                            width += deltax;
                            ffiNotesTrackIdSetOffTime(
                              widget.widgetRaw.pointer,
                              widget.id,
                              x / BEAT_WIDTH + width / BEAT_WIDTH,
                            );

                            bool shouldRefreshAll = false;
                            for (var id in widget.selectedIds.value) {
                              if (id == widget.id) {
                                continue;
                              } else {
                                shouldRefreshAll = true;
                              }

                              double startTime = ffiNotesTrackIdGetOnTime(
                                widget.widgetRaw.pointer,
                                id,
                              );

                              double endTime = ffiNotesTrackIdGetOffTime(
                                widget.widgetRaw.pointer,
                                id,
                              );

                              double x = startTime * BEAT_WIDTH;
                              double width = (endTime - startTime) * BEAT_WIDTH;

                              width += deltax;
                              ffiNotesTrackIdSetOffTime(
                                widget.widgetRaw.pointer,
                                id,
                                x / BEAT_WIDTH + width / BEAT_WIDTH,
                              );
                            }

                            if (shouldRefreshAll) {
                              setState(() {});
                              widget.selectedIds.notifyListeners();
                            } else {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PitchEventWidget extends StatefulWidget {
  PitchEventWidget(
      {required this.index,
      required this.start,
      required this.length,
      required this.num,
      required this.selectedIds,
      required this.widgetRaw})
      : super(key: UniqueKey());

  int index;
  double start;
  double length;
  int num;

  RawWidget widgetRaw;

  ValueNotifier<List<int>> selectedIds;

  @override
  State<PitchEventWidget> createState() => _PitchEventWidgetState();
}

class _PitchEventWidgetState extends State<PitchEventWidget> {
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
    return Container(
      color: Colors.grey,
    );
  }
}

class PianoRollPainter extends CustomPainter {
  PianoRollPainter({
    required this.horizontal,
    required this.vertical,
  });

  final ScrollController horizontal;
  final ScrollController vertical;

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

        double tempY = 2;
        if (vertical.hasClients) {
          tempY = 2 + vertical.offset;
        }

        final textSpan = TextSpan(
            text: (x / BEAT_WIDTH ~/ MEASURE_BEATS + 1).toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 10));
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: 100);
        final offset = Offset(x + 0.0 + 4, tempY);
        textPainter.paint(canvas, offset);
      } else {
        canvas.drawLine(
            Offset(x + 0.0, 0), Offset(x + 0.0, size.height), paint5);
      }

      beat += 1;
    }

    n = 1;
    for (int y = size.height.toInt(); y > 0; y -= STEP_HEIGHT.toInt()) {
      if (n == 12) {
        canvas.drawLine(
          Offset(0, y + 0.0),
          Offset(size.width, y + 0.0),
          paint3,
        );

        final textSpan = TextSpan(
          text: "C" + (12 - (y / STEP_HEIGHT ~/ 8)).toString(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(minWidth: 0, maxWidth: 100);

        double tempX = 2;
        if (horizontal.hasClients) {
          tempX = 2 + horizontal.offset;
        }

        final offset = Offset(tempX, y + 0.0 - 14);
        textPainter.paint(canvas, offset);
      }

      if (n < 12) {
        n += 1;
      } else {
        n = 1;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PianoRollPainter oldDelegate) {
    if (horizontal.hasClients && oldDelegate.horizontal.hasClients) {
      return horizontal.offset != oldDelegate.horizontal.offset;
    } else {
      return false;
    }
  }
}

class NotesMapWidget extends StatefulWidget {
  NotesMapWidget(this.notes, this.horizontal, this.vertical, this.size);

  final List<NoteWidget> notes;
  final ScrollController horizontal;
  final ScrollController vertical;
  final ui.Size size;

  @override
  _NotesMapWidget createState() => _NotesMapWidget();
}

class _NotesMapWidget extends State<NotesMapWidget> {
  double MAP_WIDTH = 200;
  double MAP_HEIGHT = 100;

  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.horizontal.addListener(update);
    widget.vertical.addListener(update);
  }

  @override
  void dispose() {
    super.dispose();
    widget.horizontal.removeListener(update);
    widget.vertical.removeListener(update);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MAP_WIDTH,
      height: MAP_HEIGHT,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: GestureDetector(
        onTapDown: (e) {
          double x = max(e.localPosition.dx, 0);
          double y = max(e.localPosition.dy, 0);

          widget.horizontal.animateTo(
            x / 200 * BEAT_WIDTH * 32 * 4,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );

          widget.vertical.animateTo(
            y / 100 * STEP_HEIGHT * STEP_COUNT,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
          setState(() {});
        },
        onPanUpdate: (e) {
          /*double offsetX =
              widget.horizontal.offset / (BEAT_WIDTH * 32 * 4) * MAP_WIDTH / 2;
          double offsetY = widget.vertical.offset /
              (STEP_HEIGHT * STEP_COUNT) *
              MAP_HEIGHT /
              2;*/

          double x = max(e.localPosition.dx, 0);
          double y = max(e.localPosition.dy, 0);

          widget.horizontal.jumpTo(x / 200 * BEAT_WIDTH * 32 * 4);
          widget.vertical.jumpTo(y / 100 * STEP_HEIGHT * STEP_COUNT);
          setState(() {});
        },
        child: CustomPaint(
          painter: NotesMapPainter(widget.notes),
          child: CustomPaint(
            painter: NotesMapWindowPainter(
                widget.size, widget.horizontal, widget.vertical),
          ),
        ),
      ),
    );
  }
}

class NotesMapPainter extends CustomPainter {
  NotesMapPainter(this.notes);

  final List<NoteWidget> notes;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1.0;

    for (var note in notes) {
      double start = ffiNotesTrackIdGetOnTime(note.widgetRaw.pointer, note.id);
      double end = ffiNotesTrackIdGetOffTime(note.widgetRaw.pointer, note.id);
      int num = ffiNotesTrackIdGetNoteOnNum(note.widgetRaw.pointer, note.id);

      double left = size.width * start / (32 * 4);
      double top = size.height / 127 * (STEP_COUNT - num);
      double width = (end - start) * size.width / (32 * 4);

      canvas.drawRect(Rect.fromLTWH(left, top, width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NotesMapPainter oldDelegate) {
    return notes != oldDelegate.notes;
  }
}

class NotesMapWindowPainter extends CustomPainter {
  NotesMapWindowPainter(this.windowSize, this.horizontal, this.vertical);

  ui.Size windowSize;
  final ScrollController horizontal;
  final ScrollController vertical;
  double paintedHorizontal = 0;
  double paintedVertical = 0;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0;

    paintedHorizontal = horizontal.offset;
    paintedHorizontal = vertical.offset;

    double x = 0;
    double y = 0;

    if (horizontal.hasClients) {
      x = horizontal.offset / (BEAT_WIDTH * 32 * 4) * size.width;
    }

    if (vertical.hasClients) {
      y = vertical.offset / (STEP_HEIGHT * STEP_COUNT) * size.height;
    }

    var width = windowSize.width / (BEAT_WIDTH * 32 * 4) * size.width;
    var height = windowSize.height / (STEP_COUNT * STEP_HEIGHT) * size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant NotesMapWindowPainter oldDelegate) {
    return paintedHorizontal != oldDelegate.horizontal.offset ||
        paintedVertical != oldDelegate.vertical.offset;
  }
}

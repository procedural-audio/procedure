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

class StepSequencerWidget extends ModuleWidget {
  StepSequencerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    step = ffiStepSequencerGetStep(widgetRaw.pointer);
  }

  int step = 0;

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
      int rows = constraints.maxHeight ~/ 42;
      int cols = constraints.maxWidth ~/ 42;

      ffiStepSequencerSetSize(widgetRaw.pointer, cols, rows);

      List<Row> rowWidgets = [];

      for (int r = 0; r < rows; r++) {
        List<Widget> pads = [];

        for (int c = 0; c < cols; c++) {
          pads.add(SequencerPad(
            color: Colors.green,
            pressed: ffiStepSequencerGetPad(widgetRaw.pointer, c, r),
            outlined: c == step,
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
          child: Column(
            children: rowWidgets,
          ));
    });
  }
}

class SequencerPad extends StatefulWidget {
  SequencerPad(
      {required this.color,
      required this.pressed,
      required this.x,
      required this.y,
      required this.outlined,
      required this.widgetRaw});

  Color color;
  bool pressed;
  bool outlined;
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
              borderRadius: BorderRadius.circular(5),
              border: widget.outlined
                  ? Border.all(
                      color: widget.pressed
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      width: 2.0)
                  : null),
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

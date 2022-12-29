import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../host.dart';
import 'widget.dart';

int Function(FFIWidgetTrait) ffiStepSequencerGetStep = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_step_sequencer_get_step")
    .asFunction();
bool Function(FFIWidgetTrait, int, int) ffiStepSequencerGetPad = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait, Int64, Int64)>>(
        "ffi_step_sequencer_get_pad")
    .asFunction();
void Function(FFIWidgetTrait, int, int, bool) ffiStepSequencerSetPad = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Int64, Int64, Bool)>>(
        "ffi_step_sequencer_set_pad")
    .asFunction();
int Function(FFIWidgetTrait) ffiStepSequencerGetRows = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_step_sequencer_get_rows")
    .asFunction();
int Function(FFIWidgetTrait) ffiStepSequencerGetCols = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_step_sequencer_get_cols")
    .asFunction();

class StepSequencerWidget extends ModuleWidget {
  StepSequencerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    step = ffiStepSequencerGetStep(widgetRaw.getTrait());
  }

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  int step = 0;

  @override
  void tick() {
    int stepNew = ffiStepSequencerGetStep(widgetRaw.getTrait());

    if (stepNew != step) {
      setState(() {
        step = stepNew;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int rows = ffiStepSequencerGetRows(widgetRaw.getTrait());
    int cols = ffiStepSequencerGetCols(widgetRaw.getTrait());

    List<Row> rowWidgets = [];

    for (int r = 0; r < rows; r++) {
      List<Widget> pads = [];

      for (int c = 0; c < cols; c++) {
        pads.add(SequencerPad(
          color: Colors.green,
          pressed: ffiStepSequencerGetPad(widgetRaw.getTrait(), c, r),
          outlined: c == step,
          x: c,
          y: r,
          widgetRaw: widgetRaw,
        ));
      }

      rowWidgets.add(Row(mainAxisSize: MainAxisSize.max, children: pads));
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 20, 20, 1.0),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
  double pressure = 1.0;

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
        widget.widgetRaw.getTrait(), widget.x, widget.y, pressed == 1);

    return Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          width: 39.5,
          height: 39.5,
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

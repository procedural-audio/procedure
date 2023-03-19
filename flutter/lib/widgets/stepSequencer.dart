import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../host.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

bool Function(FFIWidgetTrait, int, int) ffiStepSequencerGetPadDown = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait, Int64, Int64)>>(
        "ffi_step_sequencer_get_pad_down")
    .asFunction();
bool Function(FFIWidgetTrait, int, int) ffiStepSequencerGetPadOutlined = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait, Int64, Int64)>>(
        "ffi_step_sequencer_get_pad_outlined")
    .asFunction();
void Function(FFIWidgetTrait, int, int) ffiStepSequencerOnPadPress = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Int64, Int64)>>(
        "ffi_step_sequencer_on_pad_press")
    .asFunction();
void Function(FFIWidgetTrait, int, int) ffiStepSequencerOnPadRelease = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Int64, Int64)>>(
        "ffi_step_sequencer_on_pad_release")
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
  StepSequencerWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

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
          pressed: ffiStepSequencerGetPadDown(widgetRaw.getTrait(), c, r),
          outlined: ffiStepSequencerGetPadOutlined(widgetRaw.getTrait(), c, r),
          x: c,
          y: r,
          onPress: (x, y) {
            setState(() {
              ffiStepSequencerOnPadPress(widgetRaw.getTrait(), c, r);
            });
          },
          onRelease: (x, y) {
            setState(() {
              ffiStepSequencerOnPadRelease(widgetRaw.getTrait(), c, r);
            });
          },
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

class SequencerPad extends StatelessWidget {
  SequencerPad(
      {required this.color,
      required this.pressed,
      required this.x,
      required this.y,
      required this.outlined,
      required this.onPress,
      required this.onRelease});

  Color color;
  bool pressed;
  bool outlined;
  int x;
  int y;
  void Function(int, int) onPress;
  void Function(int, int) onRelease;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          width: 39.5,
          height: 39.5,
          decoration: BoxDecoration(
              color: pressed ? color : color.withAlpha(50),
              borderRadius: BorderRadius.circular(5),
              border: outlined
                  ? Border.all(
                      color: pressed
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      width: 2.0)
                  : null),
          child: GestureDetector(
            onTapDown: (details) => onPress(x, y),
            onTapUp: (details) => onRelease(x, y),
          ),
        ));
  }
}

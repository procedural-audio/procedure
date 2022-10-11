import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ffi';

import 'dart:ui' as ui;

import '../views/settings.dart';

double Function(FFIWidgetPointer) ffiSimpleKnobGetValue = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_simple_knob_get_value")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiSimpleKnobSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_simple_knob_set_value")
    .asFunction();

int Function(FFIWidgetPointer) ffiSimpleKnobGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_simple_knob_get_color")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiSimpleKnobSetColor = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int32)>>(
        "ffi_simple_knob_set_color")
    .asFunction();

Pointer<Utf8> Function(FFIWidgetPointer) ffiSimpleKnobGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_simple_knob_get_label")
    .asFunction();
void Function(FFIWidgetPointer, Pointer<Utf8>) ffiSimpleKnobSetLabel = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Pointer<Utf8>)>>(
        "ffi_simple_knob_set_label")
    .asFunction();

class SimpleKnobWidget extends ModuleWidget {
  SimpleKnobWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  Color color = Colors.blue;
  double angle = 0;
  String? labelText;

  Color pickerColor = const Color(0xff443a49);

  @override
  Widget createEditor(BuildContext context) {
    // Maximum and minimum
    // Step value
    // Label
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: const Text("Simple Knob",
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        /*Container(
          padding: const EdgeInsets.all(10),
          child: Slider(
            value: ffiSimpleKnobGetValue(widgetRaw.pointer),
            label: "Value",
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (v) {
              ffiSimpleKnobSetValue(widgetRaw.pointer, v);
              setState(() { });
            },
          ),
        ),*/
        Container(
          padding: const EdgeInsets.all(10),
          child: TextField(
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(labelText: "Label"),
            onChanged: (label) {
              //ffiSimpleKnobSetValue(widgetRaw.pointer, double.parse(value));
              var labelRaw = label.toNativeUtf8();
              ffiSimpleKnobSetLabel(widgetRaw.pointer, labelRaw);
              calloc.free(labelRaw);
            },
            onEditingComplete: () {
              setState(() {});
            },
          ),
        ),
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(10)),
            child: TextButton(
              child: Container(),
              onPressed: () {
                setState(() {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Pick a color"),
                          titleTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          contentTextStyle:
                              const TextStyle(color: Colors.white),
                          backgroundColor: MyTheme.grey50,
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: pickerColor,
                              onColorChanged: changeColor,
                              colorPickerWidth: 300,
                              pickerAreaHeightPercent: 0.7,
                              portraitOnly: true,
                            ),
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text('Got it'),
                              onPressed: () {
                                ffiSimpleKnobSetColor(
                                    widgetRaw.pointer, pickerColor.value);
                                setState(() {});
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      });
                });
              },
            )),
      ],
    );
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    var colorIndex = ffiSimpleKnobGetColor(widgetRaw.pointer);
    color = Color(colorIndex);

    var labelRaw = ffiSimpleKnobGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    int width = 50;
    int height = 50;

    /*if (choosingColor) {
      choosingColor = false;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: changeColor,
              ),
              // Use Material color picker:
              //
              // child: MaterialPicker(
              //   pickerColor: pickerColor,
              //   onColorChanged: changeColor,
              //   showLabel: true, // only on portrait mode
              // ),
              //
              // Use Block color picker:
              //
              // child: BlockPicker(
              //   pickerColor: currentColor,
              //   onColorChanged: changeColor,
              // ),
              //
              // child: MultipleChoiceBlockPicker(
              //   pickerColors: currentColors,
              //   onColorsChanged: changeColors,
              // ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Got it'),
                onPressed: () {
                  setState(() => currentColor = pickerColor);
                  Navigator.of(context).pop();
                },
              )
            ]
          );
        }
      );
    }*/

    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: 2.2,
                endAngle: angle + 2.5,
                color: color,
                shouldGlow: true,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: angle - 1.55,
                endAngle: 2.5 - angle,
                color: MyTheme.grey60,
                shouldGlow: false,
              ),
            ),
          ),
        ),
        Positioned(
          top: 9.0,
          left: 9.0,
          child: Stack(children: [
            Transform.rotate(
              angle: angle,
              alignment: Alignment.center,
              child: Container(
                width: width - 10.0,
                height: height - 10.0,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 2.0,
                          spreadRadius: 0.5,
                        )
                      ]),
                ),
              ),
            )
          ]),
        ),
        Positioned(
          top: 2.0,
          left: 2.0,
          child: SizedBox(
            width: width + 20,
            height: height + 20,
            child: GestureDetector(
              onVerticalDragUpdate: (details) => setState(() {
                // angle += -details.delta.dy / 60 * globals.zoom;
                // ^^^ changed this during refactor

                angle += -details.delta.dy / 60;

                ffiSimpleKnobSetValue(widgetRaw.pointer, (angle + 2.5) / 5);

                if (angle > 2.5) {
                  angle = 2.5;
                } else if (angle < -2.5) {
                  angle = -2.5;
                }

                setState(() {
                  this.angle = angle;
                });

                //api.ffiWidgetSetFloat(widgetRaw, knobValue, angle / 2.5);
              }),
            ),
          ),
        ),
        Positioned(
          top: 52,
          child: SizedBox(
            height: 18,
            child: Text(
              labelText,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none),
            ),
          ),
        )
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  ArcPainter(
      {required this.startAngle,
      required this.endAngle,
      required this.color,
      required this.shouldGlow});

  final double startAngle;
  final double endAngle;
  final Color color;
  final bool shouldGlow;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        startAngle, //radians
        endAngle, //radians
        false,
        paint1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

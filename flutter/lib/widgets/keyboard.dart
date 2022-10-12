import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../host.dart';
import 'widget.dart';
import 'dart:ffi';

int Function(FFIWidgetPointer) ffiKeyboardGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_keyboard_get_color")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiKeyboardSetColor = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int32)>>(
        "ffi_keyboard_set_color")
    .asFunction();

class KeyboardWidget extends ModuleWidget {
  KeyboardWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    color = Color(ffiKeyboardGetColor(widgetRaw.pointer));
  }

  late Color color;

  @override
  Widget createEditor(BuildContext context) {
    // SHOULD DO showOverlay LIKE IN EXAMPLE ONLINE INSTEAD OF THIS
    return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          child: ColorPicker(
            pickerColor: color,
            pickerAreaHeightPercent: 1.0,
            onColorChanged: (c) {
              ffiKeyboardSetColor(widgetRaw.pointer, color.value);

              setState(() {
                color = c;
              });
            },
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    const double KEY_WIDTH = 25;
    const double KEY_SPACING = 1.0;
    const double KEY_HEIGHT = 60;

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
              //color: Colors.grey,
              borderRadius: BorderRadius.circular(10)),
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

                if (x + KEY_WIDTH > constraints.maxWidth) {
                  break;
                }
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
}

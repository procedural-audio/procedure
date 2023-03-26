import 'package:flutter/material.dart';
import '../patch.dart';
import 'widget.dart';
import 'dart:ffi';
import '../core.dart';
import '../module.dart';
import '../main.dart';

int Function(FFIWidgetTrait) ffiKeyboardGetKeyCount = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetTrait)>>(
        "ffi_keyboard_get_key_count")
    .asFunction();
bool Function(FFIWidgetTrait, int) ffiKeyboardKeyGetDown = core
    .lookup<NativeFunction<Bool Function(FFIWidgetTrait, Int64)>>(
        "ffi_keyboard_key_get_down")
    .asFunction();
void Function(FFIWidgetTrait, int) ffiKeyboardKeyPress = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Int64)>>(
        "ffi_keyboard_key_press")
    .asFunction();
void Function(FFIWidgetTrait, int) ffiKeyboardKeyRelease = core
    .lookup<NativeFunction<Void Function(FFIWidgetTrait, Int64)>>(
        "ffi_keyboard_key_release")
    .asFunction();

class KeyboardWidget extends ModuleWidget {
  KeyboardWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const double KEY_WIDTH = 25;
      const double KEY_SPACING = 1.0;
      double KEY_HEIGHT = constraints.maxHeight - 8;

      List<Widget> whiteKeys = [];
      List<Widget> blackKeys = [];

      int keyCount = ffiKeyboardGetKeyCount(widgetRaw.getTrait());

      double x = 0.0;
      for (int i = 0; i < keyCount; i++) {
        int j = i % 12;
        if (j == 1 || j == 3 || j == 6 || j == 8 || j == 10) {
          blackKeys.add(Positioned(
              left: x - KEY_WIDTH * 1 / 3,
              top: 0,
              child: KeyWidget(
                index: i,
                onPress: (i) {
                  setState(() {
                    print("Playing note " + i.toString());
                    ffiKeyboardKeyPress(widgetRaw.getTrait(), i);
                  });
                },
                onRelease: (i) {
                  setState(() {
                    ffiKeyboardKeyRelease(widgetRaw.getTrait(), i);
                  });
                },
                color: Colors.black,
                down: ffiKeyboardKeyGetDown(widgetRaw.getTrait(), i),
                width: KEY_WIDTH * 2 / 3,
                spacing: KEY_SPACING,
                height: KEY_HEIGHT * 2 / 3,
              )));
        } else {
          whiteKeys.add(Positioned(
              left: x,
              top: 0,
              child: KeyWidget(
                index: i,
                onPress: (i) {
                  setState(() {
                    print("Playing note " + i.toString());
                    ffiKeyboardKeyPress(widgetRaw.getTrait(), i);
                  });
                },
                onRelease: (i) {
                  setState(() {
                    ffiKeyboardKeyRelease(widgetRaw.getTrait(), i);
                  });
                },
                color: Colors.white,
                down: ffiKeyboardKeyGetDown(widgetRaw.getTrait(), i),
                width: KEY_WIDTH,
                spacing: KEY_SPACING,
                height: KEY_HEIGHT,
              )));

          x += KEY_WIDTH;
        }
      }

      return Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 4,
          controller: controller,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: controller,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Container(
                      width: x,
                      height: KEY_HEIGHT,
                      color: const Color.fromRGBO(20, 20, 20, 1.0),
                      child: Stack(
                        children: whiteKeys + blackKeys,
                      )))));
    });
  }
}

class KeyWidget extends StatelessWidget {
  KeyWidget(
      {required this.index,
      required this.color,
      required this.down,
      required this.width,
      required this.spacing,
      required this.height,
      required this.onPress,
      required this.onRelease});

  int index;
  Color color;
  bool down;
  double width;
  double spacing;
  double height;
  void Function(int) onPress;
  void Function(int) onRelease;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(spacing),
        child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (details) {
              onPress(index);
            },
            onPointerUp: (details) {
              onRelease(index);
            },
            onPointerCancel: (details) {
              onRelease(index);
            },
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: width - spacing * 2,
                height: height,
                decoration: BoxDecoration(
                    color: down ? color.withOpacity(0.5) : color,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(0), bottom: Radius.circular(3))),
              ),
            )));
  }
}

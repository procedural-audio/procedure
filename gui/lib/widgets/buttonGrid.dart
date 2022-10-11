import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../views/settings.dart';
import 'dart:ffi';

var value = "value".toNativeUtf8();
var outlined = "outline".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

/*
class ButtonGridWidget extends ModuleWidget {
  ButtonGridWidget(FFINode m, FFIWidget w) : super(m, w);

  String labelText = "Label";

  @override
  Widget build(BuildContext context) {
    int dimensionX = getInt("dimensionx");
    int dimensionY = getInt("dimensiony");

    var elements = <Widget>[];

    for (int i = 0; i < dimensionX; i++) {
      for (int j = 0; j < dimensionY; j++) {
        elements.add(
          Positioned(
            left: i * (width / dimensionX) + 2.0 + 0.0,
            top: j * (height / dimensionY) + 2.0 + 0.0,
            child: ButtonGridElement(
              pressed: api.ffiWidgetGetIntIndexed(widgetRaw, i * dimensionX + j, value) == 1,
              outlined: api.ffiWidgetGetIntIndexed(widgetRaw, i * dimensionX + j, outlined) == 1,
              width: width / dimensionX,
              height: height / dimensionY,
              color1: Colors.red,
              color2: Colors.redAccent,
              onPress: (details) {
                var curr = api.ffiWidgetGetIntIndexed(widgetRaw, i * dimensionX + j, value);
                api.ffiWidgetSetIntIndexed(widgetRaw, i * dimensionX + j, value, curr == 1 ? 0 : 1);
                api.ffiNodeUpdate(moduleRaw);
                refresh();
              },
              onRelease: (details) {
                /*api.mWidgetSetIntIndexed(moduleIndex, widgetIndex, i * dimensionX + j, value, 0);
                api.mUpdateModule(moduleIndex);
                refresh();*/
              }
            ),
          )
        );
      }
    }

    return Positioned(
      left: x + 0.0,
      top: y + 0.0,
      child: Container(
        width: width + 2.0,
        height: height + 2.0,
        child: Stack(
          children: elements,
        ),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

class ButtonGridElement extends StatelessWidget {
  final double width;
  final double height;
  final Color color1;
  final Color color2;
  final bool pressed;
  final bool outlined;

  final void Function(PointerDownEvent) onPress;
  final void Function(PointerUpEvent) onRelease;

  ButtonGridElement({required this.pressed, required this.outlined, required this.width, required this.height, required this.color1, required this.color2, required this.onPress, required this.onRelease});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPress,
      onPointerUp: onRelease,
      child: Container(
        width: width - 2 + 0.0,
        height: height - 2 + 0.0,
        decoration: BoxDecoration(
          border: outlined ? Border.all(
            color: Colors.grey,
            width: 2.0
          ) : null,
          gradient: pressed ?
            RadialGradient(
              colors: [
                color2,
                color1,
              ],
              radius: 1.2,
              focalRadius: 10,
            ) :
            RadialGradient(
              colors: [
                color1.withAlpha(50),
                color1.withAlpha(50),
              ],
              radius: 1.2,
              focalRadius: 10,
            ),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
*/
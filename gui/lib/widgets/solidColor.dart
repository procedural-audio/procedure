import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../host.dart';
import 'widget.dart';
import 'dart:ffi';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

int Function(FFIWidgetPointer) ffiSolidColorGetColor = core
    .lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>(
        "ffi_solid_color_get_color")
    .asFunction();
void Function(FFIWidgetPointer, int) ffiSolidColorSetColor = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int32)>>(
        "ffi_solid_color_set_color")
    .asFunction();

class SolidColorWidget extends ModuleWidget {
  SolidColorWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    color = Color(ffiSolidColorGetColor(widgetRaw.pointer));
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
            //colorPickerWidth: 120,
            //paletteType: PaletteType.hsvWithHue,
            pickerAreaHeightPercent: 1.0,
            onColorChanged: (c) {
              ffiSolidColorSetColor(widgetRaw.pointer, color.value);

              setState(() {
                color = c;
              });
            },
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    color = Color(ffiSolidColorGetColor(widgetRaw.pointer));

    return Container(decoration: BoxDecoration(color: color));
  }
}

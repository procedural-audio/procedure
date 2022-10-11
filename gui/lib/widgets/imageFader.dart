import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';

import '../config.dart';

var knobValue = "value".toNativeUtf8();
var colorValue = "color".toNativeUtf8();

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();
void Function(FFIWidgetPointer, double) ffiImageFaderSetValue = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_image_fader_set_value")
    .asFunction();
Pointer<Utf8> Function(FFIWidgetPointer) ffiImageFaderGetLabel = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_image_fader_get_label")
    .asFunction();

class ImageFaderWidget extends ModuleWidget {
  ImageFaderWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    _image = _loadImage(contentPath +
        "/assets/images/widgets/fader/slider_horizontal_128_frames.png");
  }

  Color color = Colors.blue;
  double value = 0.5;
  String? labelText;

  late Future<ui.Image> _image;

  Future<ui.Image> _loadImage(String imagePath) async {
    ByteData bd = await rootBundle.load(imagePath);
    final Uint8List bytes = Uint8List.view(bd.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;

    return image;
  }

  @override
  Widget createEditor(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    var labelRaw = ffiImageFaderGetLabel(widgetRaw.pointer);
    var labelText = labelRaw.toDartString();
    calloc.free(labelRaw);

    return Stack(children: [
      //SliderTheme(data: data, child: child)
      Container(
        constraints: const BoxConstraints.expand(),
        child: FutureBuilder<ui.Image>(
            future: _image,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CustomPaint(
                  painter: FaderPainter(snapshot.data!, value),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),

      GestureDetector(
        onVerticalDragUpdate: (details) => setState(() {
          value += -details.delta.dy / 200;

          if (value > 1.0) {
            value = 1.0;
          } else if (value < 0.0) {
            value = 0.0;
          }

          ffiImageFaderSetValue(widgetRaw.pointer, value);

          print("Value is " + value.toString());
        }),
      ),
    ]);
  }
}

class FaderPainter extends CustomPainter {
  FaderPainter(this.image, this.value);

  ui.Image image;
  double value;

  @override
  void paint(Canvas canvas, ui.Size size) {
    print("Size is " + size.width.toString());

    if (value > 0.99) {
      value = 0.99;
    }

    double height = image.height / 128.0;
    int offset = (value * 128).toInt();

    Paint paint = Paint();
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = true;

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, height * offset, image.width + 0.0, height),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint);
  }

  @override
  bool shouldRepaint(FaderPainter oldDelegate) {
    return value != oldDelegate.value;
  }
}

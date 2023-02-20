import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'widget.dart';
import 'dart:ffi';
import '../host.dart';

import 'dart:ui' as ui;

int Function(FFIWidgetPointer) ffiSampleFilePickerGetBufferLength = core
    .lookup<NativeFunction<Int64 Function(FFIWidgetPointer)>>(
        "ffi_sample_file_picker_get_buffer_length")
    .asFunction();
double Function(FFIWidgetPointer, int) ffiSampleFilePickerGetSampleLeft = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer, Int64)>>(
        "ffi_sample_file_picker_get_sample_left")
    .asFunction();
double Function(FFIWidgetPointer, int) ffiSampleFilePickerGetSampleRight = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer, Int64)>>(
        "ffi_sample_file_picker_get_sample_right")
    .asFunction();
void Function(FFIWidgetPointer, Pointer<Utf8>) ffiSampleFilePickerSetSample =
    core
        .lookup<NativeFunction<Void Function(FFIWidgetPointer, Pointer<Utf8>)>>(
            "ffi_sample_file_picker_set_sample")
        .asFunction();

class SamplePickerWidget extends ModuleWidget {
  SamplePickerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    refreshBuffer();
  }

  List<double> leftBuffer = [0.0];
  List<double> rightBuffer = [0.0];

  bool loadingSample = false;
  bool hovering = false;

  void refreshBuffer() {
    leftBuffer.clear();
    rightBuffer.clear();

    int count = 300;
    int length = ffiSampleFilePickerGetBufferLength(widgetRaw.pointer);

    for (int i = 0; i < count; i++) {
      int index = (length ~/ count) * i;

      double left = ffiSampleFilePickerGetSampleLeft(widgetRaw.pointer, index);
      double right =
          ffiSampleFilePickerGetSampleRight(widgetRaw.pointer, index);

      leftBuffer.add(left * 1.0);
      rightBuffer.add(right * 1.0);
    }
  }

  void browseForSample() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var path = result.files.single.path;
      if (path != null) {
        var pathRaw = path.toNativeUtf8();
        ffiSampleFilePickerSetSample(widgetRaw.pointer, pathRaw);
        calloc.free(pathRaw);

        refreshBuffer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (e) {
          setState(() {
            hovering = true;
          });
        },
        onExit: (e) {
          setState(() {
            hovering = false;
          });
        },
        child: Container(
            decoration: const BoxDecoration(
                color: Color.fromRGBO(20, 20, 20, 1.0),
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(
                  painter: SamplePainter(
                      leftBuffer: leftBuffer, rightBuffer: rightBuffer)),
              AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: hovering ? 1.0 : 0.0,
                  child: Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                          icon: const Icon(Icons.folder),
                          iconSize: 18,
                          color: Colors.grey,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              loadingSample = true;
                            });

                            browseForSample();

                            setState(() {
                              loadingSample = false;
                            });
                          }))),
              Visibility(
                  visible: loadingSample,
                  child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                          ))))
            ])));
  }
}

class SamplePainter extends CustomPainter {
  SamplePainter({
    required this.leftBuffer,
    required this.rightBuffer,
  });

  List<double> leftBuffer;
  List<double> rightBuffer;

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    int red = 0;

    /* Draw left buffers */

    List<Offset> points = [];

    red += 30;
    paint.color = paint.color.withRed(red);

    for (int i = 0; i < leftBuffer.length; i++) {
      double x = i * (size.width / leftBuffer.length);
      double y = size.height * leftBuffer[i] * 0.5;

      if (y > 0) {
        y = -y;
      }

      Offset end = Offset(x, y + size.height * 0.5);
      points.add(end);
    }

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
    points.clear();

    /* Draw right buffers */

    paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    red = 0;

    points.clear();

    red += 30;
    paint.color = paint.color.withRed(red);

    for (int i = 0; i < rightBuffer.length; i++) {
      double x = i * (size.width / rightBuffer.length);
      double y = size.height * rightBuffer[i] * 0.5;

      if (y < 0) {
        y = -y;
      }

      Offset end = Offset(x, y + size.height * 0.5);

      points.add(end);
    }

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
    points.clear();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

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

class SamplePickerWidget extends ModuleWidget {
  SamplePickerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    refreshBuffers();
  }

  List<double> leftBuffer = [0.0];
  List<double> rightBuffer = [0.0];

  void refreshBuffers() {
    leftBuffer.clear();
    rightBuffer.clear();

    int count = 300;
    int length = ffiSampleFilePickerGetBufferLength(widgetRaw.pointer);

    for (int i = 0; i < count; i++) {
      int index = (length ~/ count) * i;

      double left = ffiSampleFilePickerGetSampleLeft(widgetRaw.pointer, index);
      double right =
          ffiSampleFilePickerGetSampleRight(widgetRaw.pointer, index);

      leftBuffer.add(left * 5);
      rightBuffer.add(right * 5);
    }
  }

  void browseForSample() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // path = result.files.single.path;
      // setString("path", path!);
      // updateWaveformPath();
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(children: [
        Expanded(
            child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(20, 20, 20, 1.0),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(5))),
                child: CustomPaint(
                    painter: SamplePainter(
                        leftBuffer: leftBuffer, rightBuffer: rightBuffer)))),
        Container(
            height: 30,
            decoration: const BoxDecoration(
                color: Color.fromRGBO(30, 30, 30, 1.0),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder),
                  iconSize: 18,
                  color: Colors.blue,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    print("Pressed a button");
                  },
                ),
                IconButton(
                    icon: const Icon(Icons.folder),
                    iconSize: 18,
                    color: Colors.blue,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      print("Pressed a button");
                    })
              ],
            ))
      ]);
    });
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

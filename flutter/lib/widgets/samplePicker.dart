import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'widget.dart';
import 'dart:ffi';
import '../host.dart';

import 'dart:ui' as ui;

/*

Features
 - Sample fade in and fade out
 - Loop
 - Loop crossfade
 - Root Pitch
 - Playback speed

*/

FFIBuffer Function(FFIWidgetPointer) ffiSamplePickerGetBuffer = core
    .lookup<NativeFunction<FFIBuffer Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_buffer")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetStart = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_start")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetStart = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_start")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetEnd = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_end")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetEnd = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_end")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetAttack = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_attack")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetAttack = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_attack")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetRelease = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_release")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetRelease = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_release")
    .asFunction();

bool Function(FFIWidgetPointer) ffiSamplePickerGetShouldLoop = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_should_loop")
    .asFunction();

void Function(FFIWidgetPointer, bool) ffiSamplePickerSetShouldLoop = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_sample_picker_set_should_loop")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetLoopStart = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_loop_start")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetLoopStart = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_loop_start")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetLoopEnd = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_loop_end")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetLoopEnd = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_loop_end")
    .asFunction();

double Function(FFIWidgetPointer) ffiSamplePickerGetLoopCrossfade = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_loop_crossfade")
    .asFunction();

void Function(FFIWidgetPointer, double) ffiSamplePickerSetLoopCrossfade = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_sample_picker_set_loop_crossfade")
    .asFunction();

bool Function(FFIWidgetPointer) ffiSamplePickerGetOneShot = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_one_shot")
    .asFunction();

void Function(FFIWidgetPointer, bool) ffiSamplePickerSetOneShot = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_sample_picker_set_one_shot")
    .asFunction();

bool Function(FFIWidgetPointer) ffiSamplePickerGetReverse = core
    .lookup<NativeFunction<Bool Function(FFIWidgetPointer)>>(
        "ffi_sample_picker_get_reverse")
    .asFunction();

void Function(FFIWidgetPointer, bool) ffiSamplePickerSetReverse = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Bool)>>(
        "ffi_sample_picker_set_reverse")
    .asFunction();

class SamplePickerWidget extends ModuleWidget {
  SamplePickerWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  /*
  double start = 0.0;
  double end = 1.0;

  double fadeIn = 0.0;
  double fadeOut = 0.0;

  double loopStart = 0.3;
  double loopEnd = 0.7;
  double crossFade = 0.0;

  bool oneShot = false;
  bool reverse = false;
  bool loop = false;
  */

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
    List<double> bufferLeft = [];
    List<double> bufferRight = [];

    return Container();

    double start = ffiSamplePickerGetStart(widgetRaw.pointer);
    double end = ffiSamplePickerGetEnd(widgetRaw.pointer);
    double attack = ffiSamplePickerGetAttack(widgetRaw.pointer);
    double release = ffiSamplePickerGetRelease(widgetRaw.pointer);

    bool shouldLoop = ffiSamplePickerGetShouldLoop(widgetRaw.pointer);
    double loopStart = ffiSamplePickerGetLoopStart(widgetRaw.pointer);
    double loopEnd = ffiSamplePickerGetLoopEnd(widgetRaw.pointer);
    double loopCrossfade = ffiSamplePickerGetLoopCrossfade(widgetRaw.pointer);

    bool oneShot = ffiSamplePickerGetOneShot(widgetRaw.pointer);
    bool reverse = ffiSamplePickerGetReverse(widgetRaw.pointer);

    /* Left buffer */

    var bufferRawLeft = ffiSamplePickerGetBuffer(widgetRaw.pointer);

    var listLeft = bufferRawLeft.pointer.asTypedList(bufferRawLeft.length);
    for (double value in listLeft) {
      bufferLeft.add(value);
    }

    calloc.free(bufferRawLeft.pointer);

    /* Right buffer */

    var bufferRawRight = ffiSamplePickerGetBuffer(widgetRaw.pointer);

    var listRight = bufferRawRight.pointer.asTypedList(bufferRawRight.length);
    for (double value in listRight) {
      bufferRight.add(value);
    }

    calloc.free(bufferRawRight.pointer);

    /* Build widget */

    return Column(children: [
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        return Container(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          child: CustomPaint(
            painter:
                SamplePainter(leftBuffer: bufferLeft, rightBuffer: bufferRight),
            child: Stack(
              children: [
                /* Expand the stack */

                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),

                /* Draw fade up and down */

                Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: CustomPaint(
                      painter: FadePainter(
                          start: start,
                          end: end,
                          fadeIn: attack,
                          fadeOut: release),
                    )),

                /* Loop background square */

                Visibility(
                    visible: shouldLoop,
                    child: Positioned(
                        left: loopStart * constraints.maxWidth,
                        right: (1 - loopEnd) * constraints.maxWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.grey.withAlpha(100),
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                loopStart +=
                                    details.delta.dx / constraints.maxWidth;
                                loopEnd +=
                                    details.delta.dx / constraints.maxWidth;
                                ffiSamplePickerSetLoopStart(
                                    widgetRaw.pointer, loopStart);
                                ffiSamplePickerSetLoopEnd(
                                    widgetRaw.pointer, loopEnd);
                              });
                            },
                          ),
                        ))),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                    width: start * constraints.maxWidth,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                    width: (1.0 - end) * constraints.maxWidth,
                  ),
                ),
                Positioned(
                  left: (start + attack / 2) * constraints.maxWidth - 6,
                  top: constraints.maxHeight / 2 - 7.5,
                  child: Container(
                    width: 15,
                    height: 15,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          attack += details.delta.dx * 2 / constraints.maxWidth;
                          attack = attack.clamp(0.0, 1.0 - start);
                          ffiSamplePickerSetAttack(widgetRaw.pointer, attack);
                        });
                      },
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(7.5)),
                      border: Border.all(
                          color: Colors.grey.withAlpha(150), width: 2.0),
                    ),
                  ),
                ),
                Positioned(
                  left: (end - release / 2) * constraints.maxWidth - 8,
                  top: constraints.maxHeight / 2 - 7.5,
                  child: Container(
                    width: 15,
                    height: 15,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          release -=
                              details.delta.dx * 2 / constraints.maxWidth;
                          release = release.clamp(0.0, 1.0);
                          ffiSamplePickerSetRelease(widgetRaw.pointer, release);
                        });
                      },
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(7.5)),
                      border: Border.all(
                          color: Colors.grey.withAlpha(150), width: 2.0),
                    ),
                  ),
                ),
                SampleFlag(
                  message: "Sample Start",
                  position: start * constraints.maxWidth,
                  flagLeft: false,
                  onMove: (x) {
                    setState(() {
                      start += x / constraints.maxWidth;
                      start = start.clamp(0.0, end);
                      ffiSamplePickerSetStart(widgetRaw.pointer, start);
                    });
                  },
                ),
                SampleFlag(
                  message: "Sample End",
                  position: end * constraints.maxWidth - 12,
                  flagLeft: true,
                  onMove: (x) {
                    setState(() {
                      end += x / constraints.maxWidth;
                      end = end.clamp(start, 1.0);
                      ffiSamplePickerSetEnd(widgetRaw.pointer, end);
                    });
                  },
                ),

                /* Loop */

                Visibility(
                  visible: shouldLoop,
                  child: SampleFlag(
                    message: "Loop Start",
                    position: loopStart * constraints.maxWidth,
                    flagLeft: false,
                    onMove: (x) {
                      setState(() {
                        loopStart += x / constraints.maxWidth;
                        loopStart = loopStart.clamp(start, end);

                        ffiSamplePickerSetLoopStart(
                            widgetRaw.pointer, loopStart);
                      });
                    },
                  ),
                ),
                Visibility(
                  visible: shouldLoop,
                  child: SampleFlag(
                    message: "Loop End",
                    position: loopEnd * constraints.maxWidth - 12,
                    flagLeft: true,
                    onMove: (x) {
                      setState(() {
                        loopEnd += x / constraints.maxWidth;
                        loopEnd = loopEnd.clamp(start, end);
                        ffiSamplePickerSetLoopEnd(widgetRaw.pointer, loopEnd);
                      });
                    },
                  ),
                )
              ],
            ),
          ),
        );
      })),
      Container(
        height: 25,
        color: const Color.fromRGBO(30, 30, 30, 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
                onTap: () {
                  setState(() {
                    ffiSamplePickerSetOneShot(widgetRaw.pointer, !oneShot);
                  });
                },
                child: Tooltip(
                    message: "One shot",
                    child: Icon(
                      Icons.plus_one_sharp,
                      color: oneShot ? Colors.blue : Colors.blue.withAlpha(100),
                      size: 20,
                    ))),
            GestureDetector(
                onTap: () {
                  setState(() {
                    ffiSamplePickerSetReverse(widgetRaw.pointer, !reverse);
                  });
                },
                child: Tooltip(
                    message: "Reverse",
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: reverse ? Colors.blue : Colors.blue.withAlpha(100),
                      size: 20,
                    ))),
            GestureDetector(
                onTap: () {
                  setState(() {
                    ffiSamplePickerSetShouldLoop(
                        widgetRaw.pointer, !shouldLoop);
                  });
                },
                child: Tooltip(
                    message: "Loop",
                    child: Icon(
                      Icons.loop,
                      color:
                          shouldLoop ? Colors.blue : Colors.blue.withAlpha(100),
                      size: 20,
                    ))),
            GestureDetector(
              onTap: () {
                browseForSample();
              },
              child: const Icon(
                Icons.folder,
                size: 20,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      )
    ]);
  }
}

class FadePainter extends CustomPainter {
  FadePainter(
      {required this.start,
      required this.end,
      required this.fadeIn,
      required this.fadeOut});

  double start;
  double end;

  double fadeIn;
  double fadeOut;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint = Paint()
      ..color = Colors.grey.withAlpha(150)
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(start * size.width, size.height),
        Offset((start + fadeIn) * size.width, 0), paint);
    canvas.drawLine(Offset(end * size.width, size.height),
        Offset((end - fadeOut) * size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class SampleFlag extends StatelessWidget {
  SampleFlag(
      {required this.position,
      required this.onMove,
      required this.flagLeft,
      required this.message});

  double position;
  Function(double) onMove;
  bool flagLeft;
  String message;

  final double width = 10.0;
  final double strokeWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: position,
        top: 0.0,
        bottom: 0.0,
        child: SizedBox(
            width: width + strokeWidth,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: flagLeft ? 0 : strokeWidth,
                  child: Tooltip(
                      message: message,
                      child: SizedBox(
                        width: width,
                        height: width + 5,
                        child: CustomPaint(
                          painter: FlagPainter(
                              paintingStyle: PaintingStyle.fill,
                              strokeColor: Colors.grey,
                              strokeWidth: 0.0,
                              isLeft: flagLeft),
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              onMove(details.delta.dx);
                            },
                          ),
                        ),
                      )),
                ),
                Positioned(
                    left: flagLeft ? width : 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: strokeWidth,
                      color: Colors.grey,
                    ))
              ],
            )));
  }
}

class FlagPainter extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final bool isLeft;

  FlagPainter(
      {this.strokeColor = Colors.black,
      this.strokeWidth = 3,
      this.paintingStyle = PaintingStyle.stroke,
      this.isLeft = false});

  @override
  void paint(Canvas canvas, ui.Size size) {
    Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = paintingStyle;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
  }

  Path getTrianglePath(double x, double y) {
    if (isLeft) {
      return Path()
        ..moveTo(0, y / 2)
        ..lineTo(x, 0)
        ..lineTo(x, y)
        ..lineTo(0, y / 2);
    } else {
      return Path()
        ..moveTo(x, y / 2)
        ..lineTo(0, 0)
        ..lineTo(0, y)
        ..lineTo(x, y / 2);
    }
  }

  @override
  bool shouldRepaint(FlagPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
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

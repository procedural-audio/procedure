import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../host.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';

import '../views/settings.dart';

//int Function(FFIWidgetPointer) ffiKnobGetValue = core.lookup<NativeFunction<Int32 Function(FFIWidgetPointer)>>("ffi_knob_get_value").asFunction();

class EnvelopeWidget extends ModuleWidget {
  EnvelopeWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    attack = 0.1;
    decay = 0.0;
    sustain = 0.5;
    release = 1.0;
  }

  late double attack;
  late double decay;
  late double sustain;
  late double release;

  @override
  Widget build(BuildContext context) {
    const double length = 50.0;

    print("A: " +
        attack.toString() +
        " D: " +
        decay.toString() +
        " S: " +
        sustain.toString() +
        " R: " +
        release.toString());

    return Container(
      color: MyTheme.grey20,
      child: CustomPaint(
        painter: EnvelopePainter(
            attack: attack, decay: decay, sustain: sustain, release: release),
        child: Stack(
          children: [
            Positioned(
                left: attack - 6,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6)),
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                    ),
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        attack += details.delta.dx;

                        if (attack < 0) {
                          attack = 0;
                        }
                        if (attack > length) {
                          attack = length;
                        }
                      });
                    },
                  ),
                )),
            Positioned(
                left: attack + decay,
                top: sustain - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(7)),
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.resizeUpRightDownLeft,
                    ),
                    onPanUpdate: (details) {
                      setState(() {
                        decay += details.delta.dx;
                        sustain += details.delta.dy;

                        if (decay < 0) {
                          decay = 0;
                        }

                        if (decay > length) {
                          decay = length;
                        }

                        if (sustain < 0) {
                          sustain = 0;
                        }

                        if (sustain > 90) {
                          sustain = 90;
                        }
                      });
                    },
                  ),
                )),
            Positioned(
                left: 150 - 6,
                top: sustain - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(7)),
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                    ),
                    onPanUpdate: (details) {
                      setState(() {
                        sustain += details.delta.dy;

                        if (sustain < 0) {
                          sustain = 0;
                        }

                        if (sustain > 90) {
                          sustain = 90;
                        }
                      });
                    },
                  ),
                )),
            Positioned(
                left: release,
                top: 78,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(7)),
                  child: GestureDetector(
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                    ),
                    onPanUpdate: (details) {
                      setState(() {
                        release += details.delta.dx;

                        if (release < 150) {
                          release = 150;
                        }

                        if (release > 225) {
                          release = 225;
                        }
                      });
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class EnvelopePainter extends CustomPainter {
  EnvelopePainter(
      {required this.attack,
      required this.decay,
      required this.sustain,
      required this.release});

  final double attack;
  final double decay;
  final double sustain;
  final double release;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var line = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    var line2 = Paint()
      ..color = Colors.grey.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, size.height), Offset(attack, 0), line);
    // canvas.drawCircle(Offset(attack, 0), 4, line);

    // canvas.drawLine(Offset(attack.dx, 0), Offset(attack.dx, size.height), line2);

    canvas.drawLine(Offset(attack, 0), Offset(attack + decay, sustain), line);

    canvas.drawLine(
        Offset(attack + decay, sustain), Offset(150, sustain), line);

    canvas.drawLine(
        Offset(150, sustain), Offset(release + 6, size.height), line);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

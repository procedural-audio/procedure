import 'package:flutter/material.dart';
import '../host.dart';
import 'widget.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';
import '../main.dart';

double Function(FFIWidgetPointer) ffiEnvelopeGetAttack = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_envelope_get_attack")
    .asFunction();
double Function(FFIWidgetPointer) ffiEnvelopeGetDecay = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_envelope_get_decay")
    .asFunction();
double Function(FFIWidgetPointer) ffiEnvelopeGetSustain = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_envelope_get_sustain")
    .asFunction();
double Function(FFIWidgetPointer) ffiEnvelopeGetRelease = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_envelope_get_release")
    .asFunction();
double Function(FFIWidgetPointer) ffiEnvelopeGetMult = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
        "ffi_envelope_get_mult")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiEnvelopeSetAttack = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_envelope_set_attack")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiEnvelopeSetDecay = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_envelope_set_decay")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiEnvelopeSetSustain = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_envelope_set_sustain")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiEnvelopeSetRelease = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_envelope_set_release")
    .asFunction();
void Function(FFIWidgetPointer, double) ffiEnvelopeSetMult = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Float)>>(
        "ffi_envelope_set_mult")
    .asFunction();

class EnvelopeWidget extends ModuleWidget {
  EnvelopeWidget(App a, RawNode m, FFIWidget w) : super(a, m, w) {}

  double attack = 0.0;
  double mult = 1.0;
  double decay = 0.0;
  double sustain = 0.0;
  double release = 0.0;

  @override
  Widget build(BuildContext context) {
    attack = ffiEnvelopeGetAttack(widgetRaw.pointer);
    mult = ffiEnvelopeGetMult(widgetRaw.pointer);
    decay = ffiEnvelopeGetDecay(widgetRaw.pointer);
    sustain = ffiEnvelopeGetSustain(widgetRaw.pointer);
    release = ffiEnvelopeGetRelease(widgetRaw.pointer);

    return LayoutBuilder(builder: (context, constraints) {
      double attackX = attack * constraints.maxWidth / 3;
      double attackY = constraints.maxHeight - mult * constraints.maxHeight;
      double decayX = decay * constraints.maxWidth / 3 + attackX;
      double decayY = ((1.0 - sustain) * constraints.maxHeight) * mult +
          constraints.maxHeight * (1.0 - mult);
      double releaseX = release * constraints.maxWidth / 3 + decayX;
      double releaseY = constraints.maxHeight;

      return Container(
          decoration: const BoxDecoration(
              color: Color.fromRGBO(20, 20, 20, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              child: CustomPaint(
                  painter: EnvelopePainter(
                      attackX: attackX,
                      attackY: attackY,
                      decayX: decayX,
                      decayY: decayY,
                      releaseX: releaseX,
                      releaseY: releaseY),
                  child: Stack(children: [
                    EnvelopeDragPoint(attackX, attackY, (x, y) {
                      attack += x / constraints.maxWidth * 3;
                      attack = attack.clamp(0.0, 1.0);
                      ffiEnvelopeSetAttack(widgetRaw.pointer, attack);

                      mult -= y / constraints.maxHeight;
                      mult = mult.clamp(0.0, 1.0);
                      ffiEnvelopeSetMult(widgetRaw.pointer, mult);
                      setState(() {});
                    }),
                    EnvelopeDragPoint(decayX, decayY, (x, y) {
                      decay += x / constraints.maxWidth * 3;
                      decay = decay.clamp(0.0, 1.0);
                      ffiEnvelopeSetDecay(widgetRaw.pointer, decay);

                      sustain -= y / constraints.maxHeight * (1 / mult);
                      sustain = sustain.clamp(0.0, 1.0);
                      ffiEnvelopeSetSustain(widgetRaw.pointer, sustain);

                      setState(() {});
                    }),
                    EnvelopeDragPoint(releaseX, releaseY, (x, y) {
                      release += x / constraints.maxWidth * 3;
                      release = release.clamp(0.0, 1.0);
                      ffiEnvelopeSetRelease(widgetRaw.pointer, release);
                      setState(() {});
                    }),
                  ]))));
    });
  }
}

class EnvelopeDragPoint extends StatefulWidget {
  EnvelopeDragPoint(this.x, this.y, this.onDrag);

  double x;
  double y;
  void Function(double, double) onDrag;

  @override
  State<StatefulWidget> createState() => _EnvelopeDragPoint();
}

class _EnvelopeDragPoint extends State<EnvelopeDragPoint> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final double size = hovering ? 20.0 : 15.0;

    return Positioned(
        left: widget.x - 10,
        top: widget.y - 10,
        child: SizedBox(
            width: 20,
            height: 20,
            child: MouseRegion(
                onEnter: (e) => setState(() {
                      hovering = true;
                    }),
                onExit: (e) => setState(() {
                      hovering = false;
                    }),
                child: GestureDetector(
                    onPanUpdate: (e) {
                      widget.onDrag(e.delta.dx, e.delta.dy);
                    },
                    child: Align(
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                                color: hovering
                                    ? const Color.fromRGBO(160, 160, 160, 1.0)
                                    : const Color.fromRGBO(120, 120, 120, 1.0),
                                borderRadius: BorderRadius.all(
                                    Radius.circular(size)))))))));
  }
}

class EnvelopePainter extends CustomPainter {
  EnvelopePainter(
      {required this.attackX,
      required this.attackY,
      required this.decayX,
      required this.decayY,
      required this.releaseX,
      required this.releaseY});

  final double attackX;
  final double attackY;
  final double decayX;
  final double decayY;
  final double releaseX;
  final double releaseY;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var line = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    var line2 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, size.height), Offset(attackX, attackY), line);
    canvas.drawLine(Offset(attackX, attackY), Offset(decayX, decayY), line);
    canvas.drawLine(Offset(decayX, decayY), Offset(releaseX, releaseY), line);
    // canvas.drawCircle(Offset(attack, 0), 4, line);

    // canvas.drawLine(Offset(attack.dx, 0), Offset(attack.dx, size.height), line2);

    // canvas.drawLine(Offset(attack, 0), Offset(attack + decay, sustain), line);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

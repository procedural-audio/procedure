import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'dart:ui' as ui;

import '../module/moduleInfo.dart';
import '../views/settings.dart';
import '../utils.dart';

class KnobWidget extends NodeWidget {
  KnobWidget(YamlMap map) : super(map);

  final bool hovering = false;
  final bool dragging = false;

  double value = 0.5;

  @override
  Map<String, dynamic> getState() {
    return {
      'value': value,
    };
  }

  @override
  void setState(Map<String, dynamic> state) {
    value = state['value'];
  }

  @override
  Widget build(BuildContext context) {
    int left = map['left'] ?? 0;
    int top = map['top'] ?? 0;
    int width = map['width'] ?? 50;
    int height = map['height'] ?? 50;
    String label = map['label'] ?? "Label";

    Color color = colorFromString(map['color']);

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: Knob(
          label: label,
          color: color,
          size: Size(width.toDouble(), height.toDouble()),
          onUpdate: (v) {
            value = v;
          },
        ),
      ),
    );
  }
}

class Knob extends StatefulWidget {
  Knob({
    this.initialValue = 0.5,
    required this.label,
    required this.size,
    required this.color,
    required this.onUpdate,
  });

  final double initialValue;
  final Size size;
  final Color color;
  final String label;
  final void Function(double) onUpdate;

  @override
  _Knob createState() => _Knob();
}

class _Knob extends State<Knob> {
  bool hovering = false;
  bool dragging = false;
  double value = 0.5;

  @override
  Widget build(BuildContext context) {
    int width = widget.size.width.toInt();
    int height = widget.size.height.toInt();

    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: 2.2,
                endAngle: (value - 0.5) * 5 + 2.5,
                color: widget.color,
                shouldGlow: true,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4.0,
          left: 4.0,
          child: SizedBox(
            width: width + -1.0,
            height: height + 0.0,
            child: CustomPaint(
              painter: ArcPainter(
                startAngle: (value - 0.5) * 5 - 1.55,
                endAngle: 2.5 - (value - 0.5) * 5,
                color: MyTheme.grey60,
                shouldGlow: false,
              ),
            ),
          ),
        ),
        Positioned(
          top: 9.0,
          left: 9.0,
          child: Stack(children: [
            Container(
              width: width - 10.0,
              height: height - 10.0,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(53, 53, 53, 1.0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(-1, -1),
                        color: Colors.white.withAlpha(50),
                        blurRadius: 1.0),
                    BoxShadow(
                        offset: const Offset(4, 4),
                        color: Colors.black.withAlpha(120),
                        blurRadius: 4.0)
                  ]),
              alignment: Alignment.topCenter,
            ),
            Transform.rotate(
              angle: (value - 0.5) * 5,
              alignment: Alignment.center,
              child: Container(
                width: width - 10.0,
                height: height - 10.0,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 2.0,
                          spreadRadius: 0.5,
                        )
                      ]),
                ),
              ),
            )
          ]),
        ),
        Positioned(
          top: 2.0,
          left: 2.0,
          child: SizedBox(
            width: width + 20,
            height: height + 20,
            child: MouseRegion(
              onEnter: (details) {
                setState(() {
                  hovering = true;
                });
              },
              onExit: (details) {
                setState(() {
                  hovering = false;
                });
              },
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  setState(() {
                    dragging = true;
                  });
                },
                onVerticalDragEnd: (details) {
                  setState(() {
                    dragging = false;
                  });
                },
                onVerticalDragCancel: () {
                  setState(() {
                    dragging = false;
                  });
                },
                onVerticalDragUpdate: (details) {
                  value += (-details.delta.dy / 60) / 5;

                  if (value > 1) {
                    value = 1.0;
                  } else if (value < 0) {
                    value = 0;
                  }

                  widget.onUpdate(value);

                  setState(() {});
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 52,
          child: SizedBox(
            height: 18,
            child: Text(
              widget.label,
              style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none),
            ),
          ),
        )
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  ArcPainter(
      {required this.startAngle,
      required this.endAngle,
      required this.color,
      required this.shouldGlow});

  final double startAngle;
  final double endAngle;
  final Color color;
  final bool shouldGlow;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        startAngle, //radians
        endAngle, //radians
        false,
        paint1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'dart:ui' as ui;

import '../module/moduleInfo.dart';
import '../views/settings.dart';
import '../utils.dart';

class FaderWidget extends NodeWidget {
  FaderWidget(YamlMap map) : super(map);

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
        child: Fader(
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

class Fader extends StatefulWidget {
  Fader({
    this.initialValue = 0.5,
    required this.label,
    required this.size,
    required this.color,
    required this.onUpdate,
  });

  final double initialValue;
  final String label;
  final Size size;
  final Color color;
  final Function(double) onUpdate;

  @override
  _FaderState createState() => _FaderState();
}

class _FaderState extends State<Fader> {
  double value = 0.5;
  String? labelText;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (e) {
            value = (1 - (e.localPosition.dy / constraints.maxHeight));
            widget.onUpdate(value.clamp(0.0, 1.0));
            setState(() {});
          },
          onPanUpdate: (e) {
            value = 1 - (e.localPosition.dy / constraints.maxHeight);
            widget.onUpdate(value.clamp(0.0, 1.0));
            setState(() {});
          },
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: constraints.maxWidth,
              height: max(constraints.maxHeight * value, 0.1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.all(
                  Radius.circular(3),
                ),
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                width: 2.0,
                color: const Color.fromRGBO(50, 50, 50, 1.0),
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
        );
      },
    );
  }
}

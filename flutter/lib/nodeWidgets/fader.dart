import 'dart:math';

import 'package:flutter/material.dart';

import '../bindings/api/endpoint.dart';
import '../module/node.dart';
import '../utils.dart';

class FaderWidget extends NodeWidget<double> {
  FaderWidget(
    Node node,
    Endpoint endpoint,
    double value, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    required this.color,
    super.key,
  }) : super(node, endpoint) {
    setValue(value);
  }

  final int left;
  final int top;
  final int width;
  final int height;
  final String label;
  final Color color;

  @override
  Map<String, dynamic> getState() {
    return {
      'value': getValue(),
    };
  }

  @override
  void setState(Map<String, dynamic> state) {
    setValue(state['value']);
  }

  static FaderWidget from(
      Node node, Endpoint endpoint, Map<String, dynamic> map) {
    return FaderWidget(
      node,
      endpoint,
      map['default'] ?? 0.5,
      left: map['left'] ?? 0,
      top: map['top'] ?? 0,
      width: map['width'] ?? 50,
      height: map['height'] ?? 50,
      label: map['label'] ?? "",
      color: colorFromString(map['color'] ?? "grey"),
    );
  }

  @override
  Widget build(BuildContext context) {
    double initialValue = getValue() ?? 0.5;
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: Fader(
          initialValue: initialValue,
          label: label,
          color: color,
          size: Size(width.toDouble(), height.toDouble()),
          onUpdate: (v) {
            setValue(v);
          },
        ),
      ),
    );
  }
}

class Fader extends StatefulWidget {
  const Fader({
    super.key,
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

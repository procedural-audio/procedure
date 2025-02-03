import 'dart:math';

import 'package:flutter/material.dart';

import '../../bindings/api/endpoint.dart';
import '../node.dart';
import '../../utils.dart';

class ScopeWidget extends NodeWidget {
  ScopeWidget(
    Node node,
    NodeEndpoint endpoint, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    required this.min,
    required this.max,
    super.key,
  }) : super(node, endpoint);

  final int left;
  final int top;
  final int width;
  final int height;
  final Color color;
  final double min;
  final double max;

  ValueNotifier<double> value = ValueNotifier(0.0);

  @override
  Map<String, dynamic> getState() {
    return {
      // TODO
    };
  }

  @override
  void setState(Map<String, dynamic> state) {
    // TODO
  }

  static ScopeWidget from(
      Node node, NodeEndpoint endpoint, Map<String, dynamic> map) {
    return ScopeWidget(
      node,
      endpoint,
      left: map['left'] ?? 0,
      top: map['top'] ?? 0,
      width: map['width'] ?? 50,
      height: map['height'] ?? 50,
      min: map['min'] ?? 0.0,
      max: map['max'] ?? 1.0,
      color: colorFromString(map['color'] ?? "grey"),
      key: UniqueKey(),
    );
  }

  @override
  void tick(Duration elapsed) {
    var newValue = readFloat();
    if (newValue != null) {
      print("new value: $newValue");
      value.value = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: ValueListenableBuilder(
          valueListenable: value,
          builder: (context, value, child) {
            return Text(
              value.toString(),
              style: TextStyle(color: color),
            );
          },
        ),
      ),
    );
  }
}

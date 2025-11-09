import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:procedure_bindings/bindings/api/endpoint.dart';
import '../node.dart';
import '../../views/settings.dart';
import '../../utils.dart';
import '../../project/theme.dart';

class LedWidget extends NodeWidget {
  LedWidget(
    NodeEditor node,
    NodeEndpoint endpoint, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    super.key,
  }) : super(node, endpoint) {
    color.value = readInt() ?? 0;
  }

  final double left;
  final double top;
  final double width;
  final double height;

  final ValueNotifier<int> color = ValueNotifier(0);

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

  @override
  void tick(Duration elapsed) {
    int? newColor = readInt();
    if (newColor != null && color.value != newColor) {
      color.value = newColor;
    }
  }

  static LedWidget from(
    NodeEditor node,
    NodeEndpoint endpoint,
    Map<String, dynamic> map,
  ) {
    return LedWidget(
      node,
      endpoint,
      left: double.tryParse(map['left'].toString()) ?? 0,
      top: double.tryParse(map['top'].toString()) ?? 0,
      width: double.tryParse(map['width'].toString()) ?? 10,
      height: double.tryParse(map['height'].toString()) ?? 10,
      key: UniqueKey(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: LedPainter(color: color),
        ),
      ),
    );
  }
}

class LedPainter extends CustomPainter {
  LedPainter({required this.color}) : super(repaint: color);

  final ValueNotifier<int> color;

  @override
  void paint(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    var paint = Paint()
      ..color = Color(color.value).withAlpha(255)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(LedPainter oldDelegate) {
    return color.value != oldDelegate.color.value;
  }
}

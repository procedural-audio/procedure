import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import '../../bindings/api/endpoint.dart';
import '../node.dart';
import '../../views/settings.dart';
import '../../utils.dart';

class TextboxWidget extends NodeWidget {
  TextboxWidget(
    Node node,
    NodeEndpoint endpoint, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    required this.color,
    required this.initialValue,
    super.key,
  }) : super(node, endpoint) {
    value = initialValue;
    writeFloat(value);
    controller.text = initialValue.toString();
  }

  final int left;
  final int top;
  final int width;
  final int height;
  final String label;
  final Color color;
  final double initialValue;

  double value = 0.0;

  TextEditingController controller = TextEditingController();

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

  static TextboxWidget from(
    Node node,
    NodeEndpoint endpoint,
    Map<String, dynamic> map,
  ) {
    return TextboxWidget(
      node,
      endpoint,
      left: map['left'] ?? 0,
      top: map['top'] ?? 0,
      width: map['width'] ?? 50,
      height: map['height'] ?? 30,
      label: map['label'] ?? "",
      color: colorFromString(map['color'] ?? "grey"),
      initialValue: map['default'] ?? 0.5,
      key: UniqueKey(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(10, 10, 10, 1.0),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            maxLines: 1,
            controller: controller,
            textAlign: TextAlign.center,
            onChanged: (s) {
              var v = double.tryParse(s);
              if (v != null) {
                value = v;
                writeFloat(value);
              }
            },
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
            decoration: InputDecoration(
              fillColor: Colors.grey,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
              contentPadding: EdgeInsets.all(5.0),
            ),
          ),
        ),
      ),
    );
  }
}

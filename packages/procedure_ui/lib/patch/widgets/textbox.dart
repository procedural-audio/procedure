import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:procedure_bindings/bindings/api/endpoint.dart';
import '../node.dart';
import '../../project/theme.dart';

class TextboxWidget extends NodeWidget {
  TextboxWidget(
    NodeEditor node,
    NodeEndpoint endpoint, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    required this.color,
    required this.initialValue,
      Key? key,
  }) : super(node, endpoint, key: key);

  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final Color color;
  final String initialValue;

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

  writeValue(String value) {
    var i = int.tryParse(value);
    if (i != null) {
      writeInt(i);
    }

    var d = double.tryParse(value);
    if (d != null) {
      writeFloat(d);
    }
  }

  static TextboxWidget from(
    NodeEditor node,
    NodeEndpoint endpoint,
    Map<String, dynamic> map,
  ) {
    return TextboxWidget(
      node,
      endpoint,
      left: double.tryParse(map['left'].toString()) ?? 0.0,
      top: double.tryParse(map['top'].toString()) ?? 0.0,
      width: double.tryParse(map['width'].toString()) ?? 50.0,
      height: double.tryParse(map['height'].toString()) ?? 50.0,
      label: map['label'].toString(),
      color: colorFromString(map['color'].toString()) ?? Colors.grey,
      initialValue: map['default'].toString(),
      key: ValueKey('textbox-${node.node.id}-${endpoint.annotation}'),
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
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(10, 10, 10, 1.0),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextFormField(
            maxLines: 1,
            initialValue: initialValue,
            textAlign: TextAlign.center,
            onChanged: (s) {
              writeValue(s);
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

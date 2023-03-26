import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';
import 'dart:ffi';

import '../main.dart';
import '../patch.dart';


/*
class ButtonText extends ModuleWidget {
  ButtonText(RawNode m, FFIWidget w) : super(m, w);

  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    bool active = getBool("value");
    String text = getString("text");
    Color color = getColor("color");

    return Positioned(
      left: x + 0.0,
      top: y + 0.0,
      child: Container(
        width: width + 0.0,
        height: height + 0.0,
        padding: const EdgeInsets.all(5),
        child: Stack(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mouseOver ? color : active ? color : color.withAlpha(100),
                fontSize: 14
              ),
            ),
            MouseRegion(
              onEnter: (event) {
                setState(() { 
                  mouseOver = true;
                });
              },
              onExit: (event) {
                setState(() { 
                  mouseOver = false;
                });
              },
            ),
            GestureDetector(
              onTap: () {
                setBool("value", !active);
                refresh();
              },
            ),
          ]
        ),
      ),
    );
  }
}
*/
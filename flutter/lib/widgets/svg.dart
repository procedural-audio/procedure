import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widget.dart';
import 'dart:io';

import '../main.dart';
import 'dart:ffi';
import '../host.dart';

/*
class SVG extends ModuleWidget {
  SVG(RawNode m, FFIWidget w) : super(m, w);

  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    String path = globals.contentPath + "/assets/icons/" + getString("path");
    Color color = getColor("color");

    return Positioned(
      left: x + 0.0,
      top: y + 0.0,
      child: Container(
        width: width + 0.0,
        height: height + 0.0,
        padding: const EdgeInsets.all(5),
        child: SvgPicture.file(
          File(path),
          color: color,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
*/
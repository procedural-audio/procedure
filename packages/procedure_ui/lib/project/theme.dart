import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:procedure_bindings/bindings/api/endpoint.dart';

class ProjectTheme {
  static final Map<EndpointKind, PinShape> pinShapes = {
    EndpointKind.stream: PinShape.circle,
    EndpointKind.event: PinShape.triangle,
    EndpointKind.value: PinShape.square, // TODO: change to diamond
  };

  static final Map<String, Color> typeColors = {
    "float32": Colors.blue,
    "float64": Colors.blue.shade800,
    "int32": Colors.purple,
    "int64": Colors.deepPurple,
    "bool": Colors.red,
    "Note": Colors.green,
  };

  static Color getColor(String type) {
    if (!typeColors.containsKey(type)) {
      // print("Unknown type color $type");
    }

    return typeColors[type] ?? Colors.grey;
  }

  static PinShape getShape(EndpointKind kind) {
    if (!pinShapes.containsKey(kind)) {
      print("Unknown pin shape: $kind");
    }

    return pinShapes[kind] ?? PinShape.unknown;
  }
}

Color? colorFromString(String color) {
  return switch (color) {
    "red" => Colors.red,
    "green" => Colors.green,
    "blue" => Colors.blue,
    "yellow" => Colors.yellow,
    "purple" => Colors.deepPurple,
    "orange" => Colors.orange,
    "pink" => Colors.pink,
    "cyan" => Colors.cyan,
    _ => null
  };
}

PinShape? shapeFromString(String? shape) {
  return switch (shape) {
    "circle" => PinShape.circle,
    "square" => PinShape.square,
    "triangle" => PinShape.triangle,
    "diamond" => PinShape.diamond,
    _ => PinShape.unknown
  };
}

enum PinShape { circle, square, triangle, diamond, unknown }
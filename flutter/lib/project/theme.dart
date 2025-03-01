import 'dart:ui';

import 'package:flutter/material.dart';
import '../bindings/api/endpoint.dart';

class ProjectTheme {
  ProjectTheme({
    required this.endpointThemes,
  });

  final List<EndpointTheme> endpointThemes;

  static ProjectTheme create() {
    return ProjectTheme(
      endpointThemes: [
        EndpointTheme(
          kind: EndpointKind.stream,
          type: null,
          shape: PinShape.circle,
          color: Colors.blue,
        ),
        EndpointTheme(
          kind: EndpointKind.event,
          type: null,
          shape: PinShape.square,
          color: Colors.green,
        ),
        EndpointTheme(
          kind: EndpointKind.value,
          type: null,
          shape: PinShape.square,
          color: Colors.red,
        ),
      ],
    );
  }

  static ProjectTheme fromJson(Map<String, dynamic> map) {
    var theme = ProjectTheme.create();
    var endpoint = map['endpoint'];
    if (endpoint != null) {
      for (var endpointMap in endpoint) {
        var kind = switch (endpointMap['kind']) {
          "stream" => EndpointKind.stream,
          "event" => EndpointKind.event,
          "value" => EndpointKind.value,
          _ => null
        };

        var type = endpointMap['type'];
        var shape = shapeFromString(endpointMap['shape']);
        var color = colorFromString(endpointMap['color']);

        theme.endpointThemes.add(
          EndpointTheme(
            kind: kind,
            type: type,
            shape: shape,
            color: color,
          ),
        );
      }
    }

    return theme;
  }

  Color getColor(String type, EndpointKind kind) {
    Color color = Colors.grey;

    for (var entry in endpointThemes) {
      if ((entry.kind == kind || entry.kind == null) &&
          (entry.type == type || entry.type == null)) {
        var themeColor = entry.color;
        if (themeColor != null) {
          color = themeColor;
        }
      }
    }

    return color;
  }

  PinShape getShape(String type, EndpointKind kind) {
    PinShape shape = PinShape.unknown;

    for (var entry in endpointThemes) {
      if ((entry.kind == kind || entry.kind == null) &&
          (entry.type == type || entry.type == null)) {
        var themeShape = entry.shape;
        if (themeShape != null) {
          shape = themeShape;
        }
      }
    }

    return shape;
  }
}

class EndpointTheme {
  EndpointTheme({
    required this.kind,
    required this.type,
    required this.shape,
    required this.color,
  });

  final EndpointKind? kind;
  final String? type;
  final PinShape? shape;
  final Color? color;
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
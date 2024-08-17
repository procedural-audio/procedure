import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'globals.dart';
import 'plugins.dart';

import 'widgets2/knob.dart';

enum WidgetType {
  knob,
  fader,
  button,
}

Color colorFromString(String color) {
  return switch (color) {
    "red" => Colors.red,
    "green" => Colors.green,
    "blue" => Colors.blue,
    "yellow" => Colors.yellow,
    "purple" => Colors.purple,
    "orange" => Colors.orange,
    "pink" => Colors.pink,
    "cyan" => Colors.cyan,
    _ => Colors.grey,
  };
}

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.map, {super.key});

  final YamlMap map;

  void copyState(NodeWidget widget);
}

class WidgetInfo {
  WidgetInfo({required this.type, required this.map});

  final WidgetType type;
  final YamlMap map;

  static WidgetInfo? from(YamlMap yaml) {
    var type = switch (yaml.keys.first) {
      "Knob" => WidgetType.knob,
      "Fader" => WidgetType.fader,
      "Button" => WidgetType.button,
      _ => null,
    };

    if (type == null) {
      print("Unknown widget type");
      return null;
    }

    return WidgetInfo(
      type: WidgetType.knob,
      map: yaml[yaml.keys.first],
    );
  }

  NodeWidget createWidget() {
    return switch (type) {
      WidgetType.knob => KnobWidget(map),
      WidgetType.fader => KnobWidget(map),
      WidgetType.button => KnobWidget(map),
    };
  }
}

class ModuleInfo {
  ModuleInfo({
    required this.name,
    required this.path,
    required this.category,
    required this.patch,
    required this.width,
    required this.height,
    required this.color,
    required this.widgetInfos,
  });

  final String name;
  final String path;
  final String category;
  final String patch;
  final int width;
  final int height;
  final Color color;
  final List<WidgetInfo> widgetInfos;

  static Future<ModuleInfo?> load(String path) async {
    var file = File(path);

    if (!await file.exists()) {
      print("Error: Module file does not exist: $path");
      return null;
    }

    String contents = await file.readAsString();
    var yaml = loadYaml(contents);

    String name = yaml['name'] ?? "Unnamed";
    int width = yaml['width'] ?? 200;
    int height = yaml['height'] ?? 150;
    String patchPath = yaml['patch'] ?? "";
    String category = yaml['category'] ?? "Uncategorized";

    List<dynamic> widgets = yaml['widgets'] ?? [];
    List<WidgetInfo> widgetInfos = [];

    for (var widget in widgets) {
      var widgetInfo = WidgetInfo.from(widget);
      if (widgetInfo != null) {
        widgetInfos.add(widgetInfo);
      } else {
        print("Error: Failed to load widget info from $widget");
      }
    }

    var color = switch (yaml['color']) {
      "red" => Colors.red,
      "green" => Colors.green,
      "blue" => Colors.blue,
      "yellow" => Colors.yellow,
      "purple" => Colors.purple,
      "orange" => Colors.orange,
      "pink" => Colors.pink,
      "cyan" => Colors.cyan,
      _ => Colors.grey,
    };

    return ModuleInfo(
      name: name,
      path: path,
      category: category,
      patch: patchPath,
      width: width,
      height: height,
      color: color,
      widgetInfos: widgetInfos,
    );
  }
}

/*class CmajorPatch {
  CmajorPatch({
    required this.path,
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.manufacturer,
    required this.isInstrument,
    required this.source,
  });

  final String path;

  String id = "";
  String name = "";
  String description = "";
  String category = "";
  String version = "";
  String manufacturer = "";
  bool isInstrument = false;
  List<String> source = [];

  static Future<CmajorPatch?> load(String path) async {
    File file = File(path);

    if (!await file.exists()) {
      print("Error: Patch file does not exist: $file.path");
      return null;
    }

    String contents = await file.readAsString();
    var json = jsonDecode(contents);
    var source = json['source'];

    return CmajorPatch(
      path: path,
      id: json['ID'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      category: json['category'] ?? "",
      version: json['version'] ?? "",
      manufacturer: json['manufacturer'] ?? "",
      isInstrument: json['isInstrument'] == "true",
      source: source is List ? source.cast<String>() : [source],
    );
  }
}*/

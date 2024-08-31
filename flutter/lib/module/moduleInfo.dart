import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/nodeWidgets/fader.dart';
import 'package:metasampler/src/rust/api/simple.dart';
import 'package:yaml/yaml.dart';

import '../globals.dart';
import '../plugins.dart';

import '../nodeWidgets/knob.dart';
import '../nodeWidgets/fader.dart';
import '../nodeWidgets/button.dart';
import '../utils.dart';

enum WidgetType {
  knob,
  fader,
  button,
}

abstract class NodeWidget extends StatelessWidget {
  const NodeWidget(this.map, {super.key});

  final YamlMap map;

  Map<String, dynamic> getState();
  void setState(Map<String, dynamic> state);
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
      type: type,
      map: yaml[yaml.keys.first],
    );
  }

  NodeWidget createWidget() {
    return switch (type) {
      WidgetType.knob => KnobWidget(map),
      WidgetType.fader => FaderWidget(map),
      WidgetType.button => KnobWidget(map),
    };
  }
}

class ModuleInfo {
  ModuleInfo({
    required this.program,
    required this.name,
    required this.path,
    required this.category,
    required this.width,
    required this.height,
    required this.color,
    required this.widgetInfos,
  });

  final CmajorProgram program;
  final String name;
  final String path;
  final String category;
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
    YamlList sources = yaml['sources'] ?? YamlList();
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

    var color = colorFromString(yaml['color']);

    var program = CmajorProgram.new();

    for (String source in sources) {
      var sourceFile = File(file.parent.path + "/" + source);
      if (!await sourceFile.exists()) {
        print("Error: Source file does not exist: $sourceFile");
        continue;
      }

      String sourceContents = await sourceFile.readAsString();
      if (!program.parse(contents: sourceContents, path: sourceFile.path)) {
        print("Error: Failed to parse source file: $sourceFile");
        return null;
      }
    }

    return ModuleInfo(
      program: program,
      name: name,
      path: path,
      category: category,
      width: width,
      height: height,
      color: color,
      widgetInfos: widgetInfos,
    );
  }
}

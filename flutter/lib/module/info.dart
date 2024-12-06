import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/ui/common.dart';
import 'package:yaml/yaml.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart';

/*class ModuleInfo {
  ModuleInfo({
    // required this.program,
    required this.name,
    required this.path,
    required this.category,
    required this.width,
    required this.height,
    required this.color,
    required this.widgetInfos,
    required this.inputInfos,
    required this.outputInfos,
  });

  // final CmajorProgram program;
  final String name;
  final String path;
  final String category;
  final int width;
  final int height;
  final Color color;
  final List<WidgetInfo> widgetInfos;
  final List<PinInfo> inputInfos;
  final List<PinInfo> outputInfos;

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

    List<PinInfo> inputInfos = [];
    for (var input in yaml['inputs'] ?? []) {
      var inputInfo = PinInfo.from(input);
      if (inputInfo != null) {
        inputInfos.add(inputInfo);
      } else {
        print("Error: Failed to load input pin info from $input");
      }
    }

    List<PinInfo> outputInfos = [];
    for (var output in yaml['outputs'] ?? []) {
      var outputInfo = PinInfo.from(output);
      if (outputInfo != null) {
        outputInfos.add(outputInfo);
      } else {
        print("Error: Failed to load output pin info from $output");
      }
    }

    var color = colorFromString(yaml['color']);

    // var program = CmajorProgram.new();

    for (String source in sources) {
      var sourceFile = File(file.parent.path + "/" + source);
      if (await sourceFile.exists()) {
        var contents = await sourceFile.readAsString();
        /*if (!program.parse(path: sourceFile.path, contents: contents)) {
          print("Failed to parse program $sourceFile");
        }*/
      } else {
        print("Error: Source file does not exist: $sourceFile");
      }
    }

    return ModuleInfo(
      // program: program,
      name: name,
      path: path,
      category: category,
      width: width,
      height: height,
      color: color,
      widgetInfos: widgetInfos,
      inputInfos: inputInfos,
      outputInfos: outputInfos,
    );
  }
}*/

/*enum WidgetType {
  knob,
  fader,
  button,
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
}*/

class Module {
  Module({
    required this.path,
    required this.name,
    required this.version,
    required this.description,
    required this.category,
    required this.color,
    required this.size,
    required this.sources,
    required this.inputs,
    required this.outputs,
  });

  String path;
  String name;
  String version;
  String description;
  List<String> category;
  Color color;
  Size size;
  List<String> sources;
  List<Endpoint> inputs;
  List<Endpoint> outputs;

  static Future<Module?> load(String path) async {
    var contents = await File(path).readAsString();
    var json = jsonDecode(contents);

    List<String> sources = [];

    /*

    // Add multiple sources
    List<String> sourcePaths = json['source'] ?? List<String>.empty();

    for (var path in sourcePaths) {
      var sourcePath = File(path).parent.path + "/" + path;
      sources.add(await File(sourcePath).readAsString());
    }
    */

    var sourceName = json['source'];
    if (sourceName != null) {
      var sourcePath = File(path).parent.path + "/" + sourceName;
      sources.add(await File(sourcePath).readAsString());
    }

    double width = double.tryParse(json['width'].toString()) ?? 200;
    double height = double.tryParse(json['height'].toString()) ?? 150;

    var node = Node.from(sources: sources);

    return Module(
      path: path,
      name: json['name'] ?? "Unnamed",
      version: json['version'] ?? "0.0.0",
      description: json['description'] ?? "Empty description",
      category: json['category'] ?? List<String>.empty(),
      color: Colors.grey,
      size: Size(width, height),
      sources: sources,
      inputs: node.inputs,
      outputs: node.outputs,
    );
  }
}

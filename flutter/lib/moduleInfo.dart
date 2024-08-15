import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum WidgetType {
  knob,
  fader,
  button,
}

class WidgetInfo {
  WidgetInfo({
    required this.type,
    required this.width,
    required this.height,
  });

  final WidgetType type;
  final int width;
  final int height;

  static Future<WidgetInfo?> load(String path) async {
    var file = File(path);

    if (!await file.exists()) {
      print("Error: Widget file does not exist: $path");
      return null;
    }

    String contents = await file.readAsString();
    var json = jsonDecode(contents);

    String name = json['name'] ?? "Unnamed";

    return null;
  }
}

class ModuleInfo {
  ModuleInfo({
    required this.name,
    required this.path,
    required this.category,
    required this.width,
    required this.height,
    required this.color,
  });

  final String name;
  final String path;
  final String category;
  final int width;
  final int height;
  final Color color;

  static Future<ModuleInfo?> load(String path) async {
    var file = File(path);

    if (!await file.exists()) {
      print("Error: Module file does not exist: $path");
      return null;
    }

    String contents = await file.readAsString();
    var json = jsonDecode(contents);

    String name = json['name'] ?? "Unnamed";
    int? width = json['width'];
    int? height = json['height'];
    String? patchPath = json['patch'];
    String? category = json['category'] ?? "Uncategorized";

    if (width == null ||
        height == null ||
        patchPath == null ||
        category == null) {
      return null;
    }

    var color = switch (json['color']) {
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

    /*File patchFile = File(file.parent.path + "/" + patchPath);
    var patch = await CmajorPatch.load(patchFile.path);

    if (patch != null) {
      return ModuleInfo(
        name: name,
        path: path,
        category: category,
        patch: patch,
        width: width,
        height: height,
        color: color,
      );
    } else {
      return null;
    }*/

    return ModuleInfo(
      name: name,
      path: path,
      category: category,
      width: width,
      height: height,
      color: color,
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

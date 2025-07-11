import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metasampler/patch/patch.dart';

import '../project/theme.dart';

List<String> pathToCategory(Directory pluginsDirectory, FileSystemEntity moduleFile) {
  // Use the sub path as a module categories
  return moduleFile.parent.path
      .replaceFirst(pluginsDirectory.path, "")
      .split("/")
    ..remove("");
}

class Module {
  Module({
    required this.name,
    required this.category,
    required this.size,
    required this.source,
    this.color,
    this.title,
    this.titleColor,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  String name;
  List<String> category;
  Size size;
  String source;
  Color? color;
  String? title;
  Color? titleColor;
  String? icon;
  Color? iconColor;
  int? iconSize;

  static Module? parse(String name, List<String> category, String source) {
    int width = 1;
    int height = 1;
    Color? color;
    String? title;
    Color? titleColor;
    String? icon;
    Color? iconColor;
    int? iconSize;

    // Try to read the main processor header
    for (var line in source.split("\n")) {
      if ((line.contains("processor") || line.contains("graph")) &&
          line.contains("main")) {
        int start = line.indexOf("[[");
        int end = line.indexOf("]]");
        String annotations = line.substring(start + 2, end);
        for (var element in annotations.split(",")) {
          element = element.replaceAll(",", "");
          if (element.contains(":")) {
            var parts = element.split(":");
            if (parts.length == 2) {
              var key = parts[0].trim();
              var value = parts[1].trim().replaceAll("\"", "");

              if (key == "width") {
                width = int.tryParse(value) ?? width;
              } else if (key == "height") {
                height = int.tryParse(value) ?? height;
              } else if (key == "color") {
                color = colorFromString(value);
              } else if (key == "title") {
                title = value.replaceAll("\"", "");
              } else if (key == "titleColor") {
                titleColor = colorFromString(value);
              } else if (key == "icon") {
                /*File iconFile = File(file.parent.path + "/" + value);
                if (await iconFile.exists()) {
                  icon = await iconFile.readAsString();
                }*/
                print("Skipping icon: $value");
              } else if (key == "iconSize") {
                iconSize = int.tryParse(value);
              } else if (key == "iconColor") {
                iconColor = colorFromString(value);
              }
            }
          }
        }
      }
    }

    return Module(
      name: name,
      category: category,
      size: Size(width.toDouble(), height.toDouble()),
      source: source,
      color: color,
      title: title,
      titleColor: titleColor,
      icon: icon,
      iconColor: iconColor,
      iconSize: iconSize,
    );
  }

  static Future<Module?> load(
    File file,
    List<String> category
  ) async {
    String name = file.name.replaceAll(".module", "");
    String source = await file.readAsString();
    return parse(name, category, source);
  }

  Map<String, dynamic> getState() {
    return {
      "name": name,
      "category": category,
      "source": source,
    };
  }

  static Module? fromState(Map<String, dynamic> state) {
    return parse(
      state["name"] ?? "",
      List<String>.from(state["category"] ?? []),
      state["source"] ?? "",
    );
  }
}

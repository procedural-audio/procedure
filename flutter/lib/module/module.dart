import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/ui/common.dart';
import 'package:yaml/yaml.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart';
import '../utils.dart';

class Module {
  Module({
    required this.name,
    // required this.description,
    required this.category,
    required this.color,
    required this.size,
    required this.source,
    required this.inputs,
    required this.outputs,
  });

  String name;
  // String description;
  List<String> category;
  Color color;
  Size size;
  String source;
  List<NodeEndpoint> inputs;
  List<NodeEndpoint> outputs;

  static Future<Module?> loadFromPatch(String path) async {
    var contents = await File(path).readAsString();
    var json = jsonDecode(contents);
    var name = json['name'] ?? "Unnamed";
    var sourcePath = File(path).parent.path + "/" + json['source'];
    var category = <String>[]; // TODO: Parse the module category
    return await Module.load(name, category, sourcePath);
  }

  static Future<Module?> load(
      String name, List<String> category, String path) async {
    String source = await File(path).readAsString();

    print("Got category $category");

    // double width = double.tryParse(json['width'].toString()) ?? 200;
    // double height = double.tryParse(json['height'].toString()) ?? 150;

    Color color = Colors.grey;
    double width = 200;
    double height = 150;

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
              var value = parts[1].trim();

              print(parts);

              if (key == "color") {
                color = colorFromString(value);
              } else if (key == "width") {
                if (parts.length == 2) {
                  width = double.tryParse(parts[1]) ?? width;
                }
              } else if (key == "height") {
                if (parts.length == 2) {
                  height = double.tryParse(parts[1]) ?? height;
                }
              }
            }
          }
        }
        print(annotations);
      }
    }

    try {
      var node = Node.from(source: source, id: 0);
      if (node == null) {
        return null;
      }

      return Module(
        name: name,
        // description: json['description'] ?? "Empty description",
        category: category,
        color: color,
        size: Size(width, height),
        source: source,
        inputs: node.inputs,
        outputs: node.outputs,
      );
    } catch (e) {
      print("Failed to create node: $e");
      return null;
    }
  }
}

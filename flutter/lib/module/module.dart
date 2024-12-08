import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/ui/common.dart';
import 'package:yaml/yaml.dart';

import '../bindings/api/endpoint.dart';
import '../bindings/api/node.dart';

class Module {
  Module({
    required this.name,
    // required this.description,
    required this.category,
    required this.color,
    required this.size,
    required this.sources,
    required this.inputs,
    required this.outputs,
  });

  String name;
  // String description;
  List<String> category;
  Color color;
  Size size;
  List<String> sources;
  List<Endpoint> inputs;
  List<Endpoint> outputs;

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
    List<String> sources = [await File(path).readAsString()];

    print("Got category $category");

    // double width = double.tryParse(json['width'].toString()) ?? 200;
    // double height = double.tryParse(json['height'].toString()) ?? 150;

    try {
      var node = Node.from(sources: sources);

      return Module(
        name: name,
        // description: json['description'] ?? "Empty description",
        category: category,
        color: Colors.grey,
        size: Size(200, 150),
        sources: sources,
        inputs: node.inputs,
        outputs: node.outputs,
      );
    } catch (e) {
      print("Failed to create node: $e");
      return null;
    }
  }
}

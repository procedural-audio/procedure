import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/patch/patch.dart';

import '../plugin/info.dart';
import '../settings.dart';
import '../preset/info.dart';

class ProjectInfo {
  ProjectInfo({
    required this.directory,
    required this.description,
    required this.image,
    required this.date,
    required this.tags,
    required this.pluginInfos
  });

  final Directory directory;
  final ValueNotifier<String> description;
  File? image;
  final ValueNotifier<DateTime> date;
  final List<String> tags;
  final List<PluginInfo> pluginInfos;

  String get path => directory.path;
  String get name => directory.name;
  File get projectFile => File(directory.path + "/project.json");
  Directory get presetsDirectory => Directory(directory.path + "/presets");
  Directory get pluginsDirectory => Directory(directory.path + "/plugins");

  static ProjectInfo blank(MainDirectory directory) {
    return ProjectInfo(
      directory: Directory(directory.projects.path + "/New Project"),
      description: ValueNotifier("Description for a new project"),
      image: null,
      date: ValueNotifier(DateTime.fromMillisecondsSinceEpoch(0)),
      tags: [],
      pluginInfos: [
        PluginInfo(username: "0xchase", repository: "test-modules", tag: "0.2", tags: ["0.1", "0.2"]),
      ]
    );
  }

  static Future<ProjectInfo?> load(Directory directory) async {
    File file = File(directory.path + "/project.json");
    if (await file.exists()) {
      String contents = await file.readAsString();
      Map<String, dynamic> json = jsonDecode(contents);
      return ProjectInfo.fromJson(directory.path, json);
    }

    return null;
  }

  Future<bool> save() async {
    if (!await projectFile.exists()) {
      await projectFile.create(recursive: true);
    }

    await projectFile.writeAsString(
      jsonEncode(
        toJson(),
      ),
    );

    return true;
  }

  static ProjectInfo fromJson(String path, Map<String, dynamic> json) {
    File? image;

    File file1 = File(path + "/background.jpg");
    if (file1.existsSync()) {
      image = file1;
    }

    File file2 = File(path + "/background.png");
    if (file2.existsSync()) {
      image = file2;
    }

    File file3 = File(path + "/background.jpeg");
    if (file3.existsSync()) {
      image = file3;
    }

    String? tags = json['tags'];

    DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
    String? dateString = json['date'];
    if (dateString != null) {
      date = DateTime.parse(dateString);
    }

    return ProjectInfo(
      directory: Directory(path),
      description: ValueNotifier(json['description']),
      image: image,
      date: ValueNotifier(date),
      tags: tags != null ? tags.split(",") : [],
      pluginInfos: [
        PluginInfo(username: "0xchase", repository: "test-modules", tag: "0.2", tags: ["0.1", "0.2"]),
      ]
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description.value,
    'date': date.value.toIso8601String(),
    'tags': tags.join(","),
  };
}

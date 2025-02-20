
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/preset/patch/patch.dart';

import '../plugins.dart';
import '../settings.dart';

class ProjectInfo {
  ProjectInfo({
    required this.directory,
    required this.description,
    required this.image,
    required this.date,
    required this.tags,
    required this.pluginInfos
  });

  String get name => directory.name;

  final Directory directory;
  final ValueNotifier<String> description;
  final ValueNotifier<File?> image;
  final ValueNotifier<DateTime> date;
  final List<String> tags;
  final List<PluginInfo> pluginInfos;

  static ProjectInfo blank(MainDirectory directory) {
    return ProjectInfo(
      directory: Directory(directory.projects.path + "/New Project",
      ),
      description: ValueNotifier("Description for a new project"),
      image: ValueNotifier(null),
      date: ValueNotifier(DateTime.fromMillisecondsSinceEpoch(0)),
      tags: [],
      pluginInfos: [PluginInfo("github.com/0xchase/test-modules", null)]
    );
  }

  static Future<ProjectInfo?> load(String path) async {
    File file = File(path + "/project.json");

    if (await file.exists()) {
      String contents = await file.readAsString();
      Map<String, dynamic> json = jsonDecode(contents);
      return ProjectInfo.fromJson(path, json);
    }

    return null;
  }

  Future<bool> save() async {
    print("Saving project info");

    File file = File(directory.path + "/project.json");

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    await file.writeAsString(
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
      image: ValueNotifier(image),
      date: ValueNotifier(date),
      tags: tags != null ? tags.split(",") : [],
      pluginInfos: [PluginInfo("github.com/0xchase/test-modules", null)]
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description.value,
        'date': date.value.toIso8601String(),
        'tags': tags.join(","),
      };
}

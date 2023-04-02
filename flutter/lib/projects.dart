import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';

import 'main.dart';
import 'patch.dart';

import 'views/info.dart';
import 'views/presets.dart';

import 'ui/ui.dart';

/* Projects */

class Projects {
  Projects(this.directory) {
    scan();
  }

  final Directory directory;

  final ValueNotifier<List<ProjectInfo>> _projects = ValueNotifier([]);

  Future<Project?> load(String name) async {
    return null;
  }

  ValueNotifier<List<ProjectInfo>> list() {
    return _projects;
  }

  void scan() async {
    List<ProjectInfo> projects = [];

    var list = await directory.list().toList();
    for (var item in list) {
      var projectInfo = await ProjectInfo.load(item.path);
      if (projectInfo != null) {
        projects.add(projectInfo);
        _projects.value = projects;
      }
    }
  }
}

/* Project */

class Project {
  Project({
    required this.info,
    required this.patch,
    required this.ui,
    required this.presets,
  });

  static Project blank() {
    var directory =
        Directory("/Users/chasekanipe/Github/assets/projects/FirstProject");
    var info = ProjectInfo.blank();
    return Project(
      info: info,
      presets: Presets(info.directory),
      patch: ValueNotifier(Patch.blank(directory)),
      ui: ValueNotifier(null),
    );
  }

  /*static Project create(
    ProjectInfo info,
    Patch patch,
    UserInterface? ui,
  ) {
    return Project(
      info: info,
      presets: Presets(info.directory),
      patch: ValueNotifier(patch),
      ui: ValueNotifier(ui),
    );
  }*/

  static Future<Project?> load(ProjectInfo info) async {
    var directory = Directory(info.directory.path + "/patches");
    var presets = Presets(info.directory);

    return Project(
      info: info,
      presets: presets,
      patch: ValueNotifier(Patch.blank(directory)),
      ui: ValueNotifier(null),
    );
  }

  final ProjectInfo info;
  final Presets presets;
  final ValueNotifier<Patch> patch;
  final ValueNotifier<UserInterface?> ui;
}

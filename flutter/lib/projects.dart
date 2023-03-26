import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';

import 'patch.dart';
import 'main.dart';

import 'views/info.dart';
import 'widgets/widget.dart';
import 'core.dart';
import 'ui/ui.dart';

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
    var list = await directory.list().toList();
    _projects.value = [];

    for (var item in list) {
      var projectInfo = await ProjectInfo.from(item.path);
      if (projectInfo != null) {
        _projects.value.add(projectInfo);
        _projects.notifyListeners();
      }
    }
  }

  bool contains(String name) {
    for (var project in _projects.value) {
      if (project.name == name) {
        return true;
      }
    }

    return false;
  }
}

class Project {
  Project({
    required this.app,
    required this.info,
    required this.patch,
    required this.ui,
    required this.patches,
    required this.uis,
  });

  static Project blank(App app) {
    return Project.create(
      app,
      ProjectInfo.blank(),
      Patch.blank(),
      null,
      [],
      [],
    );
  }

  static Project create(
    App app,
    ProjectInfo info,
    Patch patch,
    UserInterface? ui,
    List<PatchInfo> patches,
    List<UserInterfaceInfo> uis,
  ) {
    return Project(
      app: app,
      info: info,
      patch: ValueNotifier(patch),
      ui: ValueNotifier(ui),
      patches: ValueNotifier(patches),
      uis: ValueNotifier(uis),
    );
  }

  final App app;
  final ProjectInfo info;
  final ValueNotifier<Patch> patch;
  final ValueNotifier<UserInterface?> ui;
  final ValueNotifier<List<PatchInfo>> patches;
  final ValueNotifier<List<UserInterfaceInfo>> uis;

  void loadPatch(String name) {}

  bool rename(String name) {
    if (!app.assets.projects.contains(name)) {
      info.name.value = name;
      return true;
    } else {
      return false;
    }
  }
}

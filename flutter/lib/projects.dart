import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';

import 'dart:async';
import 'dart:io';

import 'main.dart';
import 'patch.dart';
import 'core.dart';

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
  }) {
    scanPatches();
    scanInterfaces();
  }

  static Project blank() {
    var projectDirectory =
        Directory("/Users/chasekanipe/Github/assets/projects/NewProject");
    var patchDirectory = Directory(projectDirectory.path + "/patches/NewPatch");
    var info = ProjectInfo.blank();
    var patch = Patch.blank(patchDirectory);
    return Project(
      info: info,
      patch: ValueNotifier(patch),
      ui: ValueNotifier(null),
    );
  }

  void loadPatch(PatchInfo patchInfo, Core core) async {
    var newPatch = Patch.load(patchInfo, PLUGINS);
    if (newPatch != null) {
      core.setPatch(newPatch);
      patch.value = newPatch;
    } else {
      var newPatch = Patch(rawPatch: patch.value.rawPatch, info: patchInfo);
      core.setPatch(newPatch);
      patch.value = newPatch;
    }
  }

  static Future<Project?> load(ProjectInfo info, Core core) async {
    var directory = Directory(info.directory.path + "/patches");

    await for (var item in directory.list()) {
      var patchDirectory = Directory(item.path);
      var patchInfo = await PatchInfo.load(patchDirectory);
      if (patchInfo != null) {
        var patch = Patch.load(patchInfo, PLUGINS);
        if (patch != null) {
          print("Loaded new project and patch");
          return Project(
            info: info,
            patch: ValueNotifier(patch),
            ui: ValueNotifier(null),
          );
        }
      }
    }

    print("Loaded blank patch");
    return Project(
      info: info,
      patch: ValueNotifier(Patch.blank(directory)),
      ui: ValueNotifier(null),
    );
  }

  void save() async {
    info.save();
    patch.value.save();
  }

  final ProjectInfo info;
  final ValueNotifier<Patch> patch;
  final ValueNotifier<UserInterface?> ui;

  final ValueNotifier<List<PatchInfo>> patches = ValueNotifier([]);
  final ValueNotifier<List<InterfaceInfo>> interfaces = ValueNotifier([]);

  void scanPatches() async {
    List<PatchInfo> infos = [];
    var patchesDir = Directory(info.directory.path + "/patches").list();
    await for (var patch in patchesDir) {
      var patchDirectory = Directory(patch.path);
      var info = await PatchInfo.load(patchDirectory);
      if (info != null) {
        infos.add(info);
        patches.value = infos;
      }
    }
  }

  void scanInterfaces() async {
    List<InterfaceInfo> infos = [];
    var interfacesDir = Directory(info.directory.path + "/interfaces").list();

    await for (var interfaceItem in interfacesDir) {
      var interfaceDirectory = Directory(interfaceItem.path);
      var info = await InterfaceInfo.load(interfaceDirectory);
      if (info != null) {
        infos.add(info);
        interfaces.value = infos;
      }
    }
  }
}

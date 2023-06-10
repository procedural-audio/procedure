import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/newTopBar.dart';

import 'dart:async';
import 'dart:io';

import 'core.dart';
import 'patch.dart';

import 'views/info.dart';
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

    _projects.notifyListeners();
  }
}

/* Project */

class Project extends StatefulWidget {
  Project({
    required this.info,
    required this.patch,
    required this.ui,
    required this.onUnload,
  }) {
    scanPatches();
    scanInterfaces();
  }

  void Function() onUnload;

  static Project blank(void Function() onUnload) {
    var projectDirectory =
        Directory(Settings2.projectsDirectory() + "/NewProject");
    var patchDirectory = Directory(projectDirectory.path + "/patches/NewPatch");
    var info = ProjectInfo.blank();
    var patch = Patch.from(PatchInfo.blank(patchDirectory));
    return Project(
      info: info,
      patch: ValueNotifier(patch),
      ui: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  void loadPatch(PatchInfo patchInfo, Core core) async {
    var newPatch = await Patch.load(patchInfo, PLUGINS);
    if (newPatch != null) {
      core.setPatch(newPatch);
      patch.value = newPatch;
    } else {
      var newPatch = Patch(rawPatch: patch.value.rawPatch, info: patchInfo);
      core.setPatch(newPatch);
      patch.value = newPatch;
    }
  }

  static Future<Project?> load(
      ProjectInfo info, Core core, void Function() onUnload) async {
    var directory = Directory(info.directory.path + "/patches");

    if (!await directory.exists()) {
      await directory.create();
    }

    await for (var item in directory.list()) {
      var patchDirectory = Directory(item.path);
      var patchInfo = await PatchInfo.load(patchDirectory);
      if (patchInfo != null) {
        var patch = await Patch.load(patchInfo, PLUGINS);
        if (patch != null) {
          print("Loaded new project and patch");
          return Project(
            info: info,
            patch: ValueNotifier(patch),
            ui: ValueNotifier(null),
            onUnload: onUnload,
          );
        }
      }
    }

    print("Loaded blank patch");
    return Project(
      info: info,
      patch: ValueNotifier(Patch.from(PatchInfo.blank(directory))),
      ui: ValueNotifier(null),
      onUnload: onUnload,
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
    var patchesDir = Directory(info.directory.path + "/patches");

    if (await patchesDir.exists()) {
      var items = patchesDir.list();
      await for (var item in items) {
        var dir = Directory(item.path);
        var info = await PatchInfo.load(dir);
        if (info != null) {
          infos.add(info);
          infos.sort((a, b) => a.name.value.compareTo(b.name.value));
          patches.value = infos;
        }
      }
    }
  }

  void scanInterfaces() async {
    List<InterfaceInfo> infos = [];
    var interfacesDir = Directory(info.directory.path + "/interfaces");

    if (await interfacesDir.exists()) {
      var items = interfacesDir.list();
      await for (var item in items) {
        var dir = Directory(item.path);
        var info = await InterfaceInfo.load(dir);
        if (info != null) {
          infos.add(info);
          interfaces.value = infos;
        }
      }
    }
  }

  @override
  _Project createState() => _Project();
}

class _Project extends State<Project> {
  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    await widget.info.save();
    await widget.info.save();

    widget.patch.value.disableTick();
    widget.onUnload();
  }

  @override
  Widget build(BuildContext context) {
    bool uiVisible = false;

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: NewTopBar(
            projectName: widget.info.name,
            instViewVisible: uiVisible,
            onViewSwitch: () {
              setState(() {
                uiVisible = !uiVisible;
              });
            },
            onUserInterfaceEdit: () {
              widget.ui.value?.toggleEditing();
            },
            onProjectClose: onProjectClose,
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (uiVisible) {
                return ValueListenableBuilder<UserInterface?>(
                  valueListenable: widget.ui,
                  builder: (context, ui, child) {
                    if (ui != null) {
                      return ui;
                    } else {
                      return Container();
                    }
                  },
                );
              } else {
                return ValueListenableBuilder<Patch>(
                  valueListenable: widget.patch,
                  builder: (context, patch, child) {
                    return patch;
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/newTopBar.dart';
import 'package:metasampler/views/presets.dart';

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
    required this.core,
    required this.info,
    required this.patch,
    required this.ui,
    required this.onUnload,
  }) {
    scanPatches();
    scanInterfaces();
  }

  static Project blank(Core core, void Function() onUnload) {
    var projectDirectory =
        Directory(Settings2.projectsDirectory() + "/NewProject");
    var patchDirectory = Directory(projectDirectory.path + "/patches/NewPatch");
    var info = ProjectInfo.blank();
    var patch = Patch.from(PatchInfo.blank(patchDirectory));
    return Project(
      core: core,
      info: info,
      patch: ValueNotifier(patch),
      ui: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  void loadPatch(PatchInfo patchInfo) async {
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
      Core core, ProjectInfo info, void Function() onUnload) async {
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
            core: core,
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
      core: core,
      info: info,
      patch: ValueNotifier(Patch.from(PatchInfo.blank(directory))),
      ui: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  void save() async {
    await info.save();
    await patch.value.save();
  }

  Core core;
  final ProjectInfo info;
  final ValueNotifier<Patch> patch;
  final ValueNotifier<UserInterface?> ui;
  void Function() onUnload;

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

const double sidebarWidth = 300;

class _Project extends State<Project> {
  ProjectSidebarDisplay display = ProjectSidebarDisplay.None;
  bool uiVisible = false;
  bool presetsVisible = false;

  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    await widget.info.save();
    await widget.info.save();

    widget.patch.value.disableTick();
    widget.onUnload();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          // Patch or user interface
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
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
                  return ValueListenableBuilder<Patch?>(
                    valueListenable: widget.patch,
                    builder: (context, patch, child) {
                      if (patch != null) {
                        return patch;
                      } else {
                        return Container();
                      }
                    },
                  );
                }
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 46,
          bottom: 0,
          child: Visibility(
            visible: presetsVisible,
            child: GestureDetector(
              behavior: presetsVisible
                  ? HitTestBehavior.opaque
                  : HitTestBehavior.deferToChild,
              onTap: () {
                setState(() {
                  presetsVisible = false;
                });
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: PresetsView(
                    patches: widget.patches,
                    interfaces: widget.interfaces,
                    onLoadPatch: (info) {
                      widget.loadPatch(info);
                      print("Load patch");
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          // Project top bar
          left: 0,
          right: 0,
          top: 0,
          child: NewTopBar(
            loadedPatch: widget.patch,
            projectInfo: widget.info,
            sidebarDisplay: display,
            onPresetsButtonTap: () {
              setState(() {
                presetsVisible = !presetsVisible;
              });
            },
            onSidebarChange: (ProjectSidebarDisplay newDisplay) {
              setState(() {
                display = newDisplay;
              });
            },
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
        AnimatedPositioned(
          // Project sidebar
          top: 40,
          bottom: 0,
          right: display != ProjectSidebarDisplay.None ? 0 : -sidebarWidth,
          curve: Curves.linearToEaseOut,
          duration: const Duration(milliseconds: 300),
          child: ProjectSidebar(
            display: display,
          ),
        ),
      ],
    );
  }
}

enum ProjectSidebarDisplay {
  None,
  Samples,
  Notes,
  Modules,
  Widgets,
  Settings,
}

class ProjectSidebar extends StatelessWidget {
  ProjectSidebar({required this.display});

  final ProjectSidebarDisplay display;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        border: Border(
          left: BorderSide(
            color: Colors.black,
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          Visibility(
            visible: display == ProjectSidebarDisplay.Samples,
            child: SamplesBrowser(),
          ),
          Visibility(
            visible: display == ProjectSidebarDisplay.Notes,
            child: NotesBrowser(),
          ),
          Visibility(
            visible: display == ProjectSidebarDisplay.Modules,
            child: ModulesBrowser(),
          ),
          Visibility(
            visible: display == ProjectSidebarDisplay.Widgets,
            child: WidgetsBrowser(),
          ),
          Visibility(
            visible: display == ProjectSidebarDisplay.Settings,
            child: Settings(),
          ),
        ],
      ),
    );
  }
}

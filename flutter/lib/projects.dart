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
    required this.interface,
    required this.onUnload,
  }) {
    scan();
  }

  final Core core;
  final ProjectInfo info;
  final ValueNotifier<Patch> patch;
  final ValueNotifier<UserInterface?> interface;
  void Function() onUnload;

  final ValueNotifier<List<PresetInfo>> presets = ValueNotifier([]);


  static Project blank(Core core, void Function() onUnload) {
    var projectDirectory =
        Directory(Settings2.projectsDirectory() + "/NewProject");
    var patchDirectory = Directory(projectDirectory.path + "/patches/NewPatch");
    var info = ProjectInfo.blank();
    var patch = Patch.from(PresetInfo.blank(patchDirectory));
    return Project(
      core: core,
      info: info,
      patch: ValueNotifier(patch),
      interface: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  Future<bool> loadPreset(PresetInfo info) async {
    var newPatch = await Patch.load(info, PLUGINS);
    if (newPatch != null) {
      core.setPatch(newPatch);
      patch.value = newPatch;

      var newInterface = await UserInterface.load(info);
      if (newInterface != null) {
        interface.value = newInterface;
        return true;
      }

      return true;
    }

    return false;
  }

  Future<bool> loadInterface(PresetInfo info) async {
    return false;
  }

  static Future<Project?> load(
      Core core, ProjectInfo info, void Function() onUnload) async {
    var directory = Directory(info.directory.path + "/presets");

    if (!await directory.exists()) {
      await directory.create();
    }

    await for (var item in directory.list()) {
      var presetsDirectory = Directory(item.path);
      var presetInfo = await PresetInfo.load(presetsDirectory);
      if (presetInfo != null) {
        var patch = await Patch.load(presetInfo, PLUGINS);
        if (patch != null) {
          print("Loaded new project and patch");
          return Project(
            core: core,
            info: info,
            patch: ValueNotifier(patch),
            interface: ValueNotifier(null),
            onUnload: onUnload,
          );
        }
      }
    }

    print("Loaded blank patch");
    return Project(
      core: core,
      info: info,
      patch: ValueNotifier(Patch.from(PresetInfo.blank(directory))),
      interface: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  void save() async {
    await info.save();
    await patch.value.save();
    await interface.value?.save();
  }

  void scan() async {
    List<PresetInfo> infos = [];
    var patchesDir = Directory(info.directory.path + "/presets");

    if (await patchesDir.exists()) {
      var items = patchesDir.list();
      await for (var item in items) {
        var dir = Directory(item.path);
        var info = await PresetInfo.load(dir);
        if (info != null) {
          infos.add(info);
          infos.sort((a, b) => a.name.value.compareTo(b.name.value));
          presets.value = infos;
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
                    valueListenable: widget.interface,
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
                    directory: Directory(widget.info.directory.path + "/presets"),
                    presets: widget.presets,
                    onLoad: (info) {
                      widget.loadPreset(info);
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
              widget.interface.value?.toggleEditing();
            },
            onSave: () {
              widget.save();
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

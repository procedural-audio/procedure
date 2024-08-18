import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/newTopBar.dart';
import 'package:metasampler/views/presets.dart';
import 'package:metasampler/window.dart';

import 'core.dart';
import 'patch/patch.dart';

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
    required this.preset,
    // required this.patch,
    // required this.interface,
    required this.onUnload,
  }) {
    scan();
  }

  final ProjectInfo info;
  final ValueNotifier<Preset> preset;
  // final ValueNotifier<Patch> patch;
  // final ValueNotifier<UserInterface?> interface;

  void Function() onUnload;

  final ValueNotifier<List<PresetInfo>> presetInfos = ValueNotifier([]);

  static Project blank(Plugins plugins, Core core, void Function() onUnload) {
    var projectDirectory =
        Directory(Settings2.projectsDirectory() + "/NewProject");
    var patchDirectory = Directory(projectDirectory.path + "/patches/NewPatch");
    var info = ProjectInfo.blank();
    var presetInfo = PresetInfo.blank(patchDirectory);

    var preset = Preset(
      info: PresetInfo.blank(patchDirectory),
      patch: Patch.from(presetInfo),
      interface: ValueNotifier(null),
    );

    return Project(
      info: info,
      preset: ValueNotifier(preset),
      // patch: ValueNotifier(patch),
      // interface: ValueNotifier(null),
      onUnload: onUnload,
    );
  }

  Future<bool> loadPreset(PresetInfo info) async {
    print("Skipping Project.loadPreset");
    /*var newPreset = await Preset.load(info, PLUGINS);

    if (newPreset != null) {
      preset.value = newPreset;
      core.setPatch(preset.value.patch);
      return true;
    }

    return false;*/
    return true;
  }

  Future<bool> loadInterface(PresetInfo info) async {
    return false;
  }

  static Future<Project?> load(
      ProjectInfo info, void Function() onUnload) async {
    var directory = Directory(info.directory.path + "/presets");

    if (!await directory.exists()) {
      await directory.create();
    }

    await for (var item in directory.list()) {
      var presetsDirectory = Directory(item.path);
      var presetInfo = await PresetInfo.load(presetsDirectory);
      if (presetInfo != null) {
        var preset = await Preset.load(presetInfo);
        if (preset != null) {
          return Project(
            info: info,
            preset: ValueNotifier(preset),
            // patch: ValueNotifier(patch),
            // interface: ValueNotifier(null),
            onUnload: onUnload,
          );
        }
      }
    }

    return null;
  }

  void save() async {
    await info.save();
    await preset.value.save();
  }

  void scan() async {
    /*List<PresetInfo> infos = [];
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
    }*/
  }

  @override
  _Project createState() => _Project();
}

const double sidebarWidth = 300;

class _Project extends State<Project> {
  ProjectSidebarDisplay display = ProjectSidebarDisplay.None;
  bool uiVisible = true;
  bool presetsVisible = false;

  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    await widget.info.save();
    await widget.preset.value.save();

    widget.preset.value.patch.disableTick();
    widget.onUnload();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset.value.interface.value == null) {
      uiVisible = false;
    }

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
                return ValueListenableBuilder<Preset>(
                    valueListenable: widget.preset,
                    builder: (context, preset, child) {
                      if (!uiVisible) {
                        return preset.patch;
                      } else {
                        return ValueListenableBuilder<UserInterface?>(
                          valueListenable: preset.interface,
                          builder: (context, ui, child) {
                            if (ui != null) {
                              return ui;
                            } else {
                              return Container();
                            }
                          },
                        );
                      }
                    });
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
                  child: PresetsBrowser(
                    directory:
                        Directory(widget.info.directory.path + "/presets"),
                    presets: widget.presetInfos,
                    onLoad: (info) {
                      widget.loadPreset(info);
                    },
                    onAddInterface: (info) async {
                      var newInterface = UserInterface(info);
                      await newInterface.save();
                      widget.preset.value.interface.value = newInterface;
                      info.hasInterface.value = true;
                    },
                    onRemoveInterface: (info) async {
                      info.hasInterface.value = false;
                      await File(info.directory.path + "/interface.json")
                          .delete();
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
            loadedPreset: widget.preset,
            projectInfo: widget.info,
            sidebarDisplay: display,
            onEdit: () {
              widget.preset.value.interface.value?.toggleEditing();
            },
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
              widget.preset.value.interface.value?.toggleEditing();
            },
            onSave: () {
              widget.save();
            },
            onUiSwitch: () {
              print("switch");
              setState(() {
                uiVisible = !uiVisible;
              });
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

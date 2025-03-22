import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugin/plugin.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/patch/newTopBar.dart';
import 'package:metasampler/preset/presets.dart';

import '../bindings/api/graph.dart' as api;

import '../patch/patch.dart';
import 'theme.dart';
import '../preset/info.dart';
import '../interface/ui.dart';
import 'info.dart';

/* Project */

class Project extends StatefulWidget {
  Project({
    super.key,
    required this.directory,
    required this.info,
    required this.preset,
    required this.plugins,
    required this.theme
  });

  final MainDirectory directory;
  final ProjectInfo info;
  Preset preset;
  List<Plugin> plugins;
  ProjectTheme theme;


  Future<bool> loadInterface(PresetInfo info) async {
    return false;
  }

  static Future<Project?> load(ProjectInfo info, MainDirectory mainDirectory) async {
    ProjectTheme theme = ProjectTheme.create();

    List<Plugin> plugins = [];
    for (var pluginInfo in info.pluginInfos) {
      var plugin = await Plugin.load(mainDirectory.plugins, pluginInfo);
      if (plugin != null) {
        plugins.add(plugin);
      }
    }

    // Create a default preset info without creating the directory
    var defaultPresetPath = info.presetsDirectory.path + "/Default";
    var defaultPresetDir = Directory(defaultPresetPath);
    var defaultPresetInfo = PresetInfo(
      directory: defaultPresetDir,
      hasInterface: false,
    );

    return Project(
      directory: mainDirectory,
      info: info,
      preset: Preset.blank(defaultPresetInfo.directory, theme, plugins),
      plugins: plugins,
      theme: theme,
    );
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
  bool uiVisible = false;
  bool presetsVisible = false;
  ValueNotifier<List<PresetInfo>> presetInfos = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> save() async {
    await widget.info.save();
    await widget.preset.save();
  }

  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    await save();

    api.clearPatch();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset.interface.value == null) {
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
                if (!uiVisible) {
                  return widget.preset.patch;
                } else {
                  return ValueListenableBuilder<UserInterface?>(
                    valueListenable: widget.preset.interface,
                    builder: (context, ui, child) {
                      if (ui != null) {
                        return ui;
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
                  child: PresetsBrowser(
                    directory: widget.info.presetsDirectory,
                    presets: presetInfos,
                    onLoad: (info) {
                      // widget.loadPreset(info);
                    },
                    onAddInterface: (info) async {
                      print("Should add interface");
                      // var newInterface = UserInterface(info);
                      // await newInterface.save();
                      // widget.preset.value.interface.value = newInterface;
                      // info.hasInterface.value = true;
                    },
                    onRemoveInterface: (info) async {
                      print("Should remove interface");
                      /*info.hasInterface.value = false;
                      await File(info.directory.path + "/interface.json")
                          .delete();*/
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
            onEdit: () {
              // widget.preset.value.interface.value?.toggleEditing();
            },
            onPresetsButtonTap: () {
              setState(() {
                presetsVisible = !presetsVisible;
              });
            },
            onViewSwitch: () {
              setState(() {
                uiVisible = !uiVisible;
              });
            },
            onUserInterfaceEdit: () {
              // widget.preset.value.interface.value?.toggleEditing();
            },
            onSave: () {
              // widget.save();
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
      ],
    );
  }
}

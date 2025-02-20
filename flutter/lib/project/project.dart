import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/newTopBar.dart';
import 'package:metasampler/preset/presets.dart';

import '../bindings/api/graph.dart' as api;

import '../preset/info.dart';
import '../views/info.dart';
import '../preset/interface/ui.dart';
import 'info.dart';

/* Project */

class Project extends StatefulWidget {
  Project({
    super.key,
    required this.directory,
    required this.info,
  });

  final MainDirectory directory;
  final ProjectInfo info;

  final ValueNotifier<List<PresetInfo>> presetInfos = ValueNotifier([]);

  static Project blank(MainDirectory directory) {
    var info = ProjectInfo.blank(directory);
    return Project(
      directory: directory,
      info: info,
    );
  }

  Future<bool> loadInterface(PresetInfo info) async {
    return false;
  }

  static Future<Project?> load(ProjectInfo info, MainDirectory mainDirectory) async {
    /*var directory = Directory(info.directory.path + "/presets");

    if (await directory.exists()) {
      await for (var item in directory.list()) {
        var presetsDirectory = Directory(item.path);
        var presetInfo = await PresetInfo.load(presetsDirectory);
        if (presetInfo != null) {
          var preset = await Preset.load(presetInfo);
          if (preset != null) {
            return Project(
              directory: mainDirectory,
              info: info,
            );
          }
        }
      }
    }*/

    return Project(
      directory: mainDirectory,
      info: info,
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
  Preset? preset;
  bool uiVisible = true;
  bool presetsVisible = false;
  List<Plugin> plugins = [];

  @override
  void initState() {
    super.initState();
    loadPlugins();
    preset = Preset.blank(Directory(widget.info.directory.path), plugins);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void save() async {
    await widget.info.save();
    await preset?.save();
  }

  void loadPlugins() async {
    for (var pluginInfo in widget.info.pluginInfos) {
      var plugin = await Plugin.load(widget.directory.plugins, pluginInfo);
      if (plugin != null) {
        plugins.add(plugin);
      }
    }
  }

  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    save();

    api.clearPatch();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (preset?.interface.value == null) {
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
                if (preset != null) {
                  if (!uiVisible) {
                    return preset!.patch;
                  } else {
                    return ValueListenableBuilder<UserInterface?>(
                      valueListenable: preset!.interface,
                      builder: (context, ui, child) {
                        if (ui != null) {
                          return ui;
                        } else {
                          return Container();
                        }
                      },
                    );
                  }
                } else {
                  return Container();
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
                    directory:
                        Directory(widget.info.directory.path + "/presets"),
                    presets: widget.presetInfos,
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
            loadedPreset: preset!,
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:metasampler/plugin/plugin.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/patch/newTopBar.dart';
import 'package:metasampler/preset/preset.dart';

import '../bindings/api/graph.dart' as api;

import '../preset/info.dart';
import 'info.dart';

/* Project */

class Project extends StatefulWidget {
  Project({
    super.key,
    required this.directory,
    required this.info,
    required this.preset,
    required this.plugins,
    required this.presetInfos,
  });

  final MainDirectory directory;
  final ProjectInfo info;
  Preset preset;
  List<Plugin> plugins;
  final List<PresetInfo> presetInfos;

  Future<bool> loadInterface(PresetInfo info) async {
    return false;
  }

  static Future<Project?> load(ProjectInfo info, MainDirectory mainDirectory) async {
    List<Plugin> plugins = [];
    for (var pluginInfo in info.pluginInfos) {
      var plugin = await Plugin.load(mainDirectory.plugins, pluginInfo);
      if (plugin != null) {
        plugins.add(plugin);
      }
    }

    // Load all available presets
    var presetsDir = info.presetsDirectory;
    List<PresetInfo> availablePresets = [];
    if (await presetsDir.exists()) {
      var items = presetsDir.list();
      await for (var item in items) {
        if (item is Directory) {
          var presetInfo = await PresetInfo.load(item);
          if (presetInfo != null) {
            availablePresets.add(presetInfo);
          }
        }
      }
    }

    // Sort presets alphabetically by name
    availablePresets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Directory newPresetDir = Directory(info.presetsDirectory.path + "/New Preset");
    Preset preset = Preset.blank(newPresetDir, plugins, false);
    if (availablePresets.isNotEmpty) {
      preset = await Preset.load(availablePresets.first, plugins, false) ?? preset;
    }

    return Project(
      directory: mainDirectory,
      info: info,
      preset: preset,
      plugins: plugins,
      presetInfos: availablePresets,
    );
  }

  @override
  _Project createState() => _Project();
}

const double sidebarWidth = 300;

class _Project extends State<Project> {
  bool uiVisible = false;
  bool presetsVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadPreset(PresetInfo info) async {
    print("Loading preset: ${info.name}");
    
    var newPreset = await Preset.load(info, widget.plugins, uiVisible);
    if (newPreset != null) {
      setState(() {
        widget.preset = newPreset;
      });
      
      // Update route with go_router
      if (mounted) {
        final encodedProjectName = Uri.encodeComponent(widget.info.name);
        final encodedPresetName = Uri.encodeComponent(info.name);
        context.go('/project/$encodedProjectName/preset/$encodedPresetName',
          extra: widget, // Pass the current widget
        );
      }
    }
  }

  void renamePreset(PresetInfo info, String newName) async {
    var newPath = info.directory.parent.path + "/" + newName;
    if (await info.directory.exists() && !await Directory(newPath).exists()) {
      await info.directory.rename(newPath);
      setState(() {
        info.directory = Directory(newPath);
      });
      
      // Update route if this is the current preset
      if (widget.preset.info == info && mounted) {
        final encodedProjectName = Uri.encodeComponent(widget.info.name);
        final encodedPresetName = Uri.encodeComponent(newName);
        context.go('/project/$encodedProjectName/preset/$encodedPresetName',
          extra: widget, // Pass the current widget
        );
      }
    }
  }

  Future<void> save() async {
    await widget.info.save();
    await widget.preset.save();
  }

  void onProjectClose() async {
    widget.info.date.value = DateTime.now();

    await save();

    api.clearPatch();
    context.go('/projects');
  }

  void newPreset() async {
    var newName = "New Preset";
    var newPath = widget.info.presetsDirectory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = "New Preset " + i.toString();
      newPath = widget.info.presetsDirectory.path + "/" + newName;
      i++;
    }

    var newInfo = PresetInfo(
      directory: Directory(newPath),
      hasInterface: false,
      tags: ["New"],
    );

    await newInfo.save();

    setState(() {
      widget.presetInfos.add(newInfo);
    });
  }

  void duplicatePreset(PresetInfo info) async {
    var newName = info.name + " (copy)";
    var newPath = info.directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = info.name + " (copy " + i.toString() + ")";
      newPath = info.directory.path + "/" + newName;
      i++;
    }

    await Process.run("cp", ["-r", info.directory.path, newPath]);
    var newInfo = await PresetInfo.load(Directory(newPath));

    if (newInfo != null) {
      setState(() {
        widget.presetInfos.add(newInfo);
      });
    }
  }

  void deletePreset(PresetInfo info) async {
    await info.directory.delete(recursive: true);
    setState(() {
      widget.presetInfos.remove(info);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        // Save project before going back
        await save();
        api.clearPatch();
        if (context.mounted) {
          context.go('/projects');
        }
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: widget.preset,
          ),
          Positioned(
            left: 0,
            top: 0,
            child: NewTopBar(
              loadedPreset: widget.preset,
              projectInfo: widget.info,
              onEdit: () {
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
              },
              onSave: () {
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
      ),
    );
  }
}

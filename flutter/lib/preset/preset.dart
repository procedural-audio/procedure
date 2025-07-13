import 'dart:io';

import 'package:flutter/material.dart';

import '../interface/ui.dart';
import '../patch/patch.dart';
import '../plugin/plugin.dart';
import '../bindings/api/patch.dart' as rust_patch;
import 'info.dart';

class Preset extends StatelessWidget {
  final PresetInfo info;
  final rust_patch.Patch rustPatch;
  final ValueNotifier<UserInterface?> interface;
  final bool uiVisible;
  final List<Plugin> plugins;

  Preset({
    required this.info,
    required this.rustPatch,
    required this.interface,
    required this.uiVisible,
    required this.plugins,
  });

  static Preset from(PresetInfo info, List<Plugin> plugins, bool uiVisible) {
    // Create a new Rust patch for the preset
    var rustPatch = rust_patch.Patch();
    return Preset(
      info: info,
      rustPatch: rustPatch,
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
    );
  }

  static Future<Preset?> load(PresetInfo info, List<Plugin> plugins, bool uiVisible) async {
    var rustPatch = rust_patch.Patch();
    
    // Try to load existing patch file
    if (await info.patchFile.exists()) {
      try {
        var contents = await info.patchFile.readAsString();
        await rustPatch.load(jsonStr: contents);
      } catch (e) {
        print("Failed to load patch: $e");
      }
    }
    
    var interface = await UserInterface.load(info);
    return Preset(
      info: info,
      rustPatch: rustPatch,
      interface: ValueNotifier(interface),
      uiVisible: uiVisible,
      plugins: plugins,
    );
  }

  static Preset blank(Directory presetDirectory, List<Plugin> plugins, bool uiVisible) {
    var info = PresetInfo(
      directory: presetDirectory,
      hasInterface: false,
    );
    var rustPatch = rust_patch.Patch();
    return Preset(
      info: info,
      rustPatch: rustPatch,
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
    );
  }

  Future<void> save() async {
    print("Saving preset");
    // Create the preset directory if it doesn't exist
    await info.directory.create(recursive: true);
    
    await info.save();
    
    // Save the Rust patch
    try {
      var jsonStr = await rustPatch.save();
      await info.patchFile.writeAsString(jsonStr);
      print("Saved patch file: ${info.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
    
    await interface.value?.save();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Builder(
        builder: (context) {
          if (!uiVisible) {
            return PatchEditor(
              presetInfo: info,
              plugins: plugins,
              patch: rustPatch,
            );
          } else {
            return ValueListenableBuilder<UserInterface?>(
              valueListenable: interface,
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
    );
  }
}
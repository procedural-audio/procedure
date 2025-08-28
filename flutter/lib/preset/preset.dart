import 'dart:io';

import 'package:flutter/material.dart';

import '../interface/ui.dart';
import '../patch/patch.dart';
import '../plugin/plugin.dart';
import '../bindings/api/node.dart' as rust_node;
import '../bindings/api/cable.dart';
import '../bindings/api/io.dart';
import 'info.dart';

class Preset extends StatelessWidget {
  final PresetInfo info;
  final List<rust_node.Node> nodes;
  final List<Cable> cables;
  final ValueNotifier<UserInterface?> interface;
  final bool uiVisible;
  final List<Plugin> plugins;
  final AudioManager? audioManager;

  Preset({
    required this.info,
    required this.nodes,
    required this.cables,
    required this.interface,
    required this.uiVisible,
    required this.plugins,
    this.audioManager,
  });

  static Preset from(PresetInfo info, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) {
    // Create empty nodes and cables lists
    return Preset(
      info: info,
      nodes: [],
      cables: [],
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  static Future<Preset?> load(PresetInfo info, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) async {
    List<rust_node.Node> nodes = [];
    List<Cable> cables = [];
    
    // Try to load existing patch file
    if (await info.patchFile.exists()) {
      try {
        var contents = await info.patchFile.readAsString();
        // TODO: Use loadPatch once bindings are regenerated
        // var result = await loadPatch(jsonStr: contents);
        // nodes = result.$1;
        // cables = result.$2;
        print("Loading patch from file (placeholder for now)");
      } catch (e) {
        print("Failed to load patch: $e");
      }
    }
    
    var interface = await UserInterface.load(info);
    return Preset(
      info: info,
      nodes: nodes,
      cables: cables,
      interface: ValueNotifier(interface),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  static Preset blank(Directory presetDirectory, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) {
    var info = PresetInfo(
      directory: presetDirectory,
      hasInterface: false,
    );
    return Preset(
      info: info,
      nodes: [],
      cables: [],
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  Future<void> save() async {
    print("Saving preset");
    // Create the preset directory if it doesn't exist
    await info.directory.create(recursive: true);
    
    await info.save();
    
    // Save the patch data
    try {
      // TODO: Use savePatch once bindings are regenerated
      // var jsonStr = await savePatch(nodes: nodes, cables: cables);
      var jsonStr = '{"nodes": [], "cables": []}';
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
              initialNodes: nodes,
              initialCables: cables,
              audioManager: audioManager,
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
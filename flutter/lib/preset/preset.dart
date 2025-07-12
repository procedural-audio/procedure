import 'dart:io';

import 'package:flutter/material.dart';

import '../interface/ui.dart';
import '../patch/patch.dart';
import '../patch/patch_manager_widget.dart';
import '../plugin/plugin.dart';
import 'info.dart';

class Preset extends StatelessWidget {
  final PresetInfo info;
  final Patch patch;
  final ValueNotifier<UserInterface?> interface;
  final bool uiVisible;
  final List<Plugin> plugins;

  Preset({
    required this.info,
    required this.patch,
    required this.interface,
    required this.uiVisible,
    required this.plugins,
  });

  static Preset from(PresetInfo info, List<Plugin> plugins, bool uiVisible) {
    return Preset(
      info: info,
      patch: Patch(info: info),
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
    );
  }

  static Future<Preset?> load(PresetInfo info, List<Plugin> plugins, bool uiVisible) async {
    var patch = await Patch.load(info, plugins);
    if (patch != null) {
      var interface = await UserInterface.load(info);
      return Preset(
        info: info,
        patch: patch,
        interface: ValueNotifier(interface),
        uiVisible: uiVisible,
        plugins: plugins,
      );
    }

    return null;
  }

  static Preset blank(Directory presetDirectory, List<Plugin> plugins, bool uiVisible) {
    var info = PresetInfo(
      directory: presetDirectory,
      hasInterface: false,
    );
    return Preset(
      info: info,
      patch: Patch(info: info),
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
    await patch.save();
    await interface.value?.save();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Builder(
        builder: (context) {
          if (!uiVisible) {
            return PatchManagerWidget(
              info: info,
              plugins: plugins,
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

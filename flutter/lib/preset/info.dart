import 'dart:io';

import 'package:metasampler/preset/patch/patch.dart';

class PresetInfo {
  PresetInfo({
    required this.directory,
    required this.hasInterface,
  });

  Directory directory;
  bool hasInterface;

  String get name => directory.name;
  File get interfaceFile => File(directory.path + "/interface.json");
  File get patchFile => File(directory.path + "/patch.json");

  static PresetInfo blank(Directory presetsDirectory) {
    return PresetInfo(
      directory: Directory(presetsDirectory.path + "/New Preset"),
      hasInterface: false,
    );
  }

  static Future<PresetInfo?> load(Directory preset) async {
    if (await preset.exists()) {
      bool interfaceExists =
          await File(preset.path + "/interface.json").exists();

      return PresetInfo(
        directory: preset,
        hasInterface: interfaceExists,
      );
    }

    return null;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:metasampler/patch/patch.dart';

import '../plugin/info.dart';
import '../plugin/plugin.dart';

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
  File get infoFile => File(directory.path + "/info.json");

  static PresetInfo blank(Directory projectDirectory) {
    var directory = Directory(projectDirectory.path + "/New Preset");
    directory.createSync(recursive: true);
    
    // Create initial patch.json
    File(directory.path + "/patch.json").createSync();
    
    return PresetInfo(
      directory: directory,
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

  Future<void> save(List<PluginInfo> plugins) async {
    if (!await infoFile.exists()) {
      await infoFile.create(recursive: true);
    }

    Map<String, dynamic> json = {
      "tags": [],
      "plugins": plugins.map((plugin) => plugin.toJson()).toList(),
    };

    await infoFile.writeAsString(
      jsonEncode(json)
    );
  }
}

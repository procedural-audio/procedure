import 'dart:convert';
import 'dart:io';

import 'package:procedure/patch/patch.dart';

class PresetInfo {
  PresetInfo({
    required this.directory,
    required this.hasInterface,
    this.tags = const [],
  });

  Directory directory;
  bool hasInterface;
  List<String> tags;

  String get name => directory.name;
  File get interfaceFile => File(directory.path + "/interface.json");
  File get patchFile => File(directory.path + "/patch.json");
  File get infoFile => File(directory.path + "/info.json");

  static PresetInfo blank(Directory projectDirectory) {
    var directory = Directory(projectDirectory.path + "/New Preset");
    
    // Create initial patch.json
    File(directory.path + "/patch.json").createSync();
    
    return PresetInfo(
      directory: directory,
      hasInterface: false,
      tags: ['Default', 'Blank'],
    );
  }

  static Future<PresetInfo?> load(Directory preset) async {
    if (await preset.exists()) {
      bool interfaceExists =
          await File(preset.path + "/interface.json").exists();

      // Read tags from info.json
      List<String> tags = [];
      File infoFile = File(preset.path + "/info.json");
      if (await infoFile.exists()) {
        try {
          String content = await infoFile.readAsString();
          Map<String, dynamic> json = jsonDecode(content);
          if (json.containsKey('tags')) {
            tags = List<String>.from(json['tags']);
          }
        } catch (e) {
          print("Error reading tags from info.json: $e");
        }
      }

      return PresetInfo(
        directory: preset,
        hasInterface: interfaceExists,
        tags: tags,
      );
    }

    return null;
  }

  Future<void> save() async {
    if (!await infoFile.exists()) {
      await infoFile.create(recursive: true);
    }

    // Exclude the 'New' tag from being saved
    List<String> tagsToSave = tags.where((tag) => tag != 'New').toList();

    Map<String, dynamic> json = {
      "tags": tagsToSave,
      // "plugins": plugins.map((plugin) => plugin.toJson()).toList(),
    };

    await infoFile.writeAsString(
      jsonEncode(json)
    );
  }
}

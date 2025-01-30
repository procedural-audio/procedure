import 'package:flutter/material.dart';
import 'package:metasampler/settings.dart';

import 'dart:io';
import 'dart:isolate';

import 'module/module.dart';
import 'patch/patch.dart';

List<String> pathToCategory(FileSystemEntity moduleFile) {
  // Use the sub path as a module categories
  return moduleFile.parent.path
      .replaceFirst(GlobalSettings.pluginsDirectory.path, "")
      .split("/")
      .sublist(2)
    ..remove("");
}

String pathToName(FileSystemEntity moduleFile) {
  return moduleFile.name.replaceAll(".module", "");
}

class Plugins {
  static final ValueNotifier<List<Module>> _modules = ValueNotifier([]);
  static Stream<FileSystemEvent>? eventStream;

  static void scan() async {
    _modules.value = [];

    // Scan all plugins for modules
    var files = GlobalSettings.pluginsDirectory
        .list(recursive: true)
        .where((item) => item.name.endsWith(".module"));

    await for (final entity in files) {
      var file = File(entity.path);
      await _createModule(file);
    }
  }

  static void openEditor() async {
    await Process.run(
      GlobalSettings.vsCodePath.path,
      [
        "--new-window",
        GlobalSettings.pluginsDirectory.path,
        GlobalSettings.pluginsDirectory.path + "/about.md",
      ],
    );
  }

  static void beginWatch() async {
    // Listen for file changes
    eventStream = GlobalSettings.pluginsDirectory
        .watch(recursive: true)
        .where((e) => e.path.endsWith(".module"))
        .where((e) => !e.isDirectory);

    // Process each event
    await for (final event in eventStream!) {
      var file = File(event.path);

      // Update the module list
      if (event is FileSystemCreateEvent) {
        // Skip if the file already exists
        if (!await file.exists()) continue;

        // Skip if the module already exists
        if (_modules.value.contains((e) => e.path == file.path)) continue;

        // Create the module
        await _createModule(file);
      } else if (event is FileSystemMoveEvent) {
        print("File ${event.path} moved");
      } else if (event is FileSystemModifyEvent) {
        if (event.contentChanged) {
          await _updateModule(event.path);
        }
      } else if (event is FileSystemDeleteEvent) {
        await _deleteModule(event.path);
      }
    }
  }

  static void endWatch() {
    eventStream = null;
  }

  static Future<void> _createModule(File file) async {
    // Use the file name as a module name
    var name = pathToName(file);
    var category = pathToCategory(file);

    // Load the module
    var module = await Module.load(name, category, file.path);
    if (module != null) {
      print("Loaded module ${file.name}");

      List<Module> modules = _modules.value;
      modules.retainWhere((m) => m.path != module.path);
      _modules.value = [...modules, module];
    } else {
      print("Failed to load module: ${file.path}");
    }
  }

  static Future<void> _updateModule(String path) async {
    var moduleFile = File(path);
    if (await moduleFile.exists()) {
      var name = pathToName(moduleFile);
      var category = pathToCategory(moduleFile);

      // Load the module
      var module = await Module.load(name, category, moduleFile.path);
      if (module != null) {
        print("Updated module ${moduleFile.path}");

        _modules.value =
            _modules.value.map((m) => m.path == path ? module : m).toList();
      }
    }
  }

  static Future<void> _deleteModule(String path) async {
    print("File ${path} deleted");
    _modules.value = _modules.value.where((m) => m.path != path).toList();
  }

  static ValueNotifier<List<Module>> get modules => _modules;
}

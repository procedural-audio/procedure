import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:procedure/bindings/api/module.dart';
import 'package:procedure/settings.dart';
import 'package:procedure/utils.dart';

import 'dart:io';

import '../patch/patch.dart';
import 'info.dart';

List<String> pathToCategory(Directory pluginsDirectory, FileSystemEntity moduleFile) {
  // Use the sub path as a module categories
  return moduleFile.parent.path
      .replaceFirst(pluginsDirectory.path, "")
      .split("/")
    ..remove("");
}

class Plugin extends ChangeNotifier {
  PluginInfo info;
  List<Module> modules;
  Directory directory;

  Plugin(this.directory, this.info, this.modules);

  static Future<Plugin?> load(Directory plugins, PluginInfo info) async {
    if (await plugins.exists()) {
      await for (var directory in plugins.list()) {
        if (directory.name.contains(".git")) {
          continue;
        }
        // TODO: Check if matches github url or branch
        // TODO: If no matches, clone repository

        if (directory is Directory) {
          // List of modules
          List<Module> modules = [];

          // Scan all plugins for modules
          var files = directory
              .list(recursive: true)
              .where((item) => item.name.endsWith(".module"));

          await for (final file in files) {
            if (file is File) {
              var category = pathToCategory(directory, file);
              var module = await Module.load(path: file.path, category: category);
              modules.add(module);
            }
          }

          print("Loaded plugin ${directory.path}");
          return Plugin(directory, info, modules);
        }
      }
    }

    return null;
  }
}

/*class Plugins extends ChangeNotifier {
  Plugins(this.pluginsDirectory);

  final List<Plugin> _plugins = [];
  final Directory pluginsDirectory;

  /*void add(String url, String? version) async {
    var plugin = await Plugin.from(url, version);
    _plugins.add(plugin);
    notifyListeners();
  }*/

  static final ValueNotifier<List<Module>> _modules = ValueNotifier([]);
  static Stream<FileSystemEvent>? eventStream;
  static ValueNotifier<GraphTheme> theme = ValueNotifier(GraphTheme.create());

  static List<String> lib(Directory pluginsDirectory) {
    return [
      File(pluginsDirectory.path + "/standard.cmajor")
          .readAsStringSync()
    ];
  }

  static void scan(Directory pluginsDirectory) async {
    _modules.value = [];

    // Scan all plugins for modules
    var files = pluginsDirectory
        .list(recursive: true)
        .where((item) => item.name.endsWith(".module"));

    await for (final entity in files) {
      var file = File(entity.path);
      await _createModule(pluginsDirectory, file);
    }

    var theme = File(pluginsDirectory.path + "/theme.json");
    await _updateTheme(theme);
  }

  static void openEditor(Directory pluginsDirectory) async {
    await Process.run(
      GlobalSettings.vsCodePath.path,
      [
        "--new-window",
        pluginsDirectory.path,
        pluginsDirectory.path + "/about.md",
      ],
    );
  }

  static void beginWatch(Directory pluginsDirectory) async {
    // Listen for file changes
    eventStream = pluginsDirectory
        .watch(recursive: true)
        .where((e) => !e.isDirectory);

    // Process each event
    await for (final event in eventStream!) {
      var file = File(event.path);

      if (file.path.endsWith(".module")) {
        // Update the module list
        if (event is FileSystemCreateEvent) {
          // Skip if the file already exists
          if (!await file.exists()) continue;

          // Skip if the module already exists
          if (_modules.value.contains((e) => e.path == file.path)) continue;

          // Create the module
          await _createModule(pluginsDirectory, file);
        } else if (event is FileSystemMoveEvent) {
          print("File ${event.path} moved");
        } else if (event is FileSystemModifyEvent) {
          if (event.contentChanged) {
            await _updateModule(pluginsDirectory, event.path);
          }
        } else if (event is FileSystemDeleteEvent) {
          await _deleteModule(event.path);
        }
      } else if (file.path.endsWith(".lib")) {
        // Update the module list
        print("Update lib file");
      } else if (file.path.endsWith("theme.json")) {
        // Update the theme
        await _updateTheme(file);
      } else {
        print("Detected change in ${event.path}");
      }
    }
  }

  static void endWatch() {
    eventStream = null;
  }

  static Future<void> _updateTheme(File file) async {
    print("Updating theme");
    var contents = await file.readAsString();
    try {
      var json = jsonDecode(contents);
      theme.value = GraphTheme.fromJson(json);
    } catch (e) {
      print("Failed to load theme: $e");
    }
  }

  static Future<void> _createModule(Directory pluginsDirectory, File file) async {
    // Use the file name as a module name
    var category = pathToCategory(pluginsDirectory, file);

    // Load the module
    var module = await Module.load(category, file);
    if (module != null) {
      print("Loaded module ${file.name}");

      List<Module> modules = _modules.value;
      modules.retainWhere((m) => m.file.path != module.file.path);
      _modules.value = [...modules, module];
    } else {
      print("Failed to load module: ${file.path}");
    }
  }

  static Future<void> _updateModule(Directory pluginDirectory, String path) async {
    var moduleFile = File(path);
    if (await moduleFile.exists()) {
      var category = pathToCategory(pluginDirectory, moduleFile);

      // Load the module
      var module = await Module.load(category, moduleFile);
      if (module != null) {
        print("Updated module ${moduleFile.path}");

        _modules.value =
            _modules.value.map((m) => m.file.path == path ? module : m).toList();
      }
    }
  }

  static Future<void> _deleteModule(String path) async {
    print("File ${path} deleted");
    _modules.value = _modules.value.where((m) => m.file.path != path).toList();
  }

  static ValueNotifier<List<Module>> get modules => _modules;
}
*/
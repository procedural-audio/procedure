import 'package:flutter/material.dart';
import 'package:metasampler/settings.dart';

import 'dart:io';
import 'dart:isolate';

import 'module/module.dart';
import 'patch/patch.dart';

class Plugins {
  static final ValueNotifier<List<Module>> _modules = ValueNotifier([]);
  static Stream<FileSystemEvent>? eventStream;

  static void scan() {
    List<Module> newModules = [];

    // Scan all plugins for modules
    GlobalSettings.pluginsDirectory
        .list(recursive: true)
        .where((item) => item.name.endsWith(".module"))
        .forEach(
      (file) async {
        // Use the file name as a module name
        var name = file.name.replaceAll(".module", "");

        // Use the sub path as a module categories
        var category = file.parent.path
            .replaceFirst(GlobalSettings.pluginsDirectory.path, "")
            .split("/")
            .sublist(2)
          ..remove("");

        var module = await Module.load(name, category, file.path);
        if (module != null) {
          print("Loaded module ${file.name} at ${file.path}");
          newModules.add(module);
        } else {
          print("Failed to load module: ${file.path}");
        }
      },
    );

    _modules.value = newModules;
  }

  static void beginWatch() async {
    // Listen for file changes
    eventStream = GlobalSettings.pluginsDirectory.watch(recursive: true);

    await for (final event in eventStream!) {
      if (event is FileSystemCreateEvent) {
        if (event.isDirectory) {
          print("Directory created");
        } else {
          print("File created");
        }
      } else if (event is FileSystemMoveEvent) {
        if (event.isDirectory) {
          print("Directory moved");
        } else {
          print("File moved");
        }
        print("File moved");
      } else if (event is FileSystemModifyEvent) {
        if (event.isDirectory) {
          print("Directory modified");
        } else {
          if (event.contentChanged) {
            print("File modified");
          } else {
            print("File modified but contents not changed");
          }
        }
      } else if (event is FileSystemDeleteEvent) {
        print("File deleted");
      }
    }
  }

  static void endWatch() {
    eventStream = null;
  }

  static ValueNotifier<List<Module>> get modules => _modules;
}

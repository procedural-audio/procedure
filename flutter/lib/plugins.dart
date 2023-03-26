import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';

import 'dart:math';
import 'dart:ffi';
import 'dart:io';

import 'settings.dart';
import 'module.dart';
import 'patch.dart';
import 'core.dart';

Plugins PLUGINS = Plugins.platformDefault();

class Plugins {
  Plugins(this.directory) {
    var pluginLoadDir = Directory(Settings2.pluginLoadDirectory());
    pluginLoadDir.listSync().forEach((e) => e.delete());

    scan();
  }

  final Directory directory;
  final ValueNotifier<List<Plugin>> _plugins = ValueNotifier([]);

  static Plugins platformDefault() {
    var path = "/Users/chasekanipe/Github/nodus/build/out/core/release/";
    var directory = Directory(path);
    return Plugins(directory);
  }

  RawModule? createModule(List<String> path) {
    for (var plugin in _plugins.value) {
      for (var moduleInfo in plugin.list().value) {
        if (moduleInfo.path == path) {
          return moduleInfo.create();
        }
      }
    }

    return null;
  }

  void scan() async {
    List<Plugin> plugins = [];
    if (await directory.exists()) {
      var items = directory.list();
      await for (var item in items) {
        var extension = ".dynamiclibraryhere";

        if (Platform.isMacOS) {
          extension = ".dylib";
        } else if (Platform.isLinux) {
          extension = ".so";
        } else if (Platform.isWindows) {
          extension = ".dll";
        } else {
          print("Unknown dynamcic library extension for platform");
        }

        if (item.path.contains(extension)) {
          var library = DynamicLibrary.open(item.path);
          if (library.providesSymbol("export_plugin")) {
            print("Found plugin at " + item.path);
            plugins.add(Plugin(item.path));
          }
        }
      }
    } else {
      print("Plugin directory doesn't exist");
    }

    _plugins.value = plugins;
  }

  ValueNotifier<List<Plugin>> list() {
    return _plugins;
  }
}

class Plugin {
  Plugin(this.path) {
    scan();
  }

  final String path;
  DynamicLibrary? library;

  final ValueNotifier<String> name = ValueNotifier("");
  final ValueNotifier<List<ModuleInfo>> _modules = ValueNotifier([]);

  void scan() async {
    // TODO: library?.close();

    var rand = Random();
    File file = File(path);
    if (await file.exists()) {
      var fileName = file.name;
      var extension = "someextensionhere";

      if (Platform.isMacOS) {
        extension = ".dylib";
      } else if (Platform.isLinux) {
        extension = ".so";
      } else if (Platform.isWindows) {
        extension = ".dll";
      } else {
        print("Unknown dynamcic library extension for platform");
      }

      var randString = ((rand.nextDouble() + 1.0) * 900000).toInt().toString();
      fileName = fileName.replaceAll(extension, randString + extension);
      var newPath = Settings2.pluginLoadDirectory() + fileName;
      var newFile = await file.copy(newPath);
      var lib = DynamicLibrary.open(newFile.path);

      print("Loaded plugin at " + newFile.path);

      var plugin = RawPlugin.from(lib);
      if (plugin != null) {
        List<ModuleInfo> modules = [];

        int count = plugin.getModuleCount();
        for (int i = 0; i < count; i++) {
          var rawModuleInfo = plugin.getModuleInfo(i);
          modules.add(ModuleInfo.from(rawModuleInfo));
        }

        library = lib;
        name.value = plugin.getName();
        _modules.value = modules;
      } else {
        print("Failed to get raw plugin");
      }
    }
  }

  ValueNotifier<List<ModuleInfo>> list() {
    return _modules;
  }
}

class RawPlugin extends Struct {
  @Int64()
  external int pointer;

  static RawPlugin? from(DynamicLibrary library) {
    if (library.providesSymbol("export_plugin")) {
      RawPlugin Function() exportPlugin = library
          .lookup<NativeFunction<RawPlugin Function()>>("export_plugin")
          .asFunction();

      return exportPlugin();
    } else {
      print("Couldn't find export in plugin");
    }

    return null;
  }

  String getName() {
    var rawName = ffiPluginGetName(this);
    var name = rawName.toDartString();
    calloc.free(rawName);
    return name;
  }

  int getVersion() {
    return ffiPluginGetVersion(this);
  }

  int getModuleCount() {
    return ffiPluginGetModuleCount(this);
  }

  RawModuleInfo getModuleInfo(int index) {
    return ffiPluginGetModuleInfo(this, index);
  }
}

Pointer<Utf8> Function(RawPlugin) ffiPluginGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(RawPlugin)>>(
        "ffi_plugin_get_name")
    .asFunction();
int Function(RawPlugin) ffiPluginGetVersion = core
    .lookup<NativeFunction<Int64 Function(RawPlugin)>>("ffi_plugin_get_version")
    .asFunction();
int Function(RawPlugin) ffiPluginGetModuleCount = core
    .lookup<NativeFunction<Int64 Function(RawPlugin)>>(
        "ffi_plugin_get_module_info_count")
    .asFunction();
RawModuleInfo Function(RawPlugin, int) ffiPluginGetModuleInfo = core
    .lookup<NativeFunction<RawModuleInfo Function(RawPlugin, Int64)>>(
        "ffi_plugin_get_module_info")
    .asFunction();

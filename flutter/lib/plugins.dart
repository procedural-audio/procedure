import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:math';
import 'dart:ffi';
import 'dart:io';

import 'settings.dart';
import 'patch.dart';
import 'core.dart';
import 'moduleInfo.dart';

var PLUGINS = Plugins.platformDefault();

class Plugin {
  Plugin(this.name, this.version, this._modules);

  final String name;
  final int version;
  final ValueNotifier<List<ModuleInfo>> _modules;

  static Future<Plugin?> load(String path) async {
    List<ModuleInfo> modules = [];

    await for (var entity in Directory(path).list(recursive: true)) {
      if (entity.path.endsWith(".cmajormodule")) {
        var module = await ModuleInfo.load(entity.path);
        if (module != null) {
          print("Loaded module ${module.name} at ${module.path}");
          modules.add(module);
        } else {
          print("Failed to load module: ${entity.path}");
        }
      }
    }

    return Plugin("Temp Plugin Name", 1, ValueNotifier(modules));
  }

  /*void scan() async {
    print("Scanning modules...");
  }*/

  ValueNotifier<List<ModuleInfo>> modules() {
    return _modules;
  }
}

class Plugins {
  Plugins(this.directory) {
    scan();

    directory.watch().listen((event) {
      reload(event.path);
    });
  }

  final Directory directory;
  final ValueNotifier<List<Plugin>> _plugins = ValueNotifier([]);

  static Plugins platformDefault() {
    var path = Settings2.pluginDirectory();
    var directory = Directory(path);
    return Plugins(directory);
  }

  void scan() async {
    print("Scanning plugins");

    List<Plugin> plugins = [];
    if (await directory.exists()) {
      var items = directory.list();
      await for (var item in items) {
        print("Scanning plugin: ${item.path}");
        var plugin = await Plugin.load(item.path);
        if (plugin != null) {
          plugins.add(plugin);
        }
      }
    } else {
      print("Plugin directory doesn't exist");
    }

    _plugins.value = plugins;

    print("Done scanning plugins");
  }

  ValueNotifier<List<Plugin>> list() {
    return _plugins;
  }

  void reload(String path) async {
    print("Reload plugin at $path");

    /*for (var plugin in _plugins.value) {
      rawPlugins.unload(plugin);
    }

    scan();*/
  }
}

/*class Plugin extends StatelessWidget {
  Plugin(this.rawPlugin, this.file) {
    List<ModuleInfo> modules = [];

    print("Skipping Plugin initializer");

    return;

    int count = rawPlugin.getModuleCount();
    for (int i = 0; i < count; i++) {
      var rawModuleInfo = rawPlugin.getModuleInfo(i);
      modules.add(ModuleInfo.from(rawModuleInfo));
    }

    _modules.value = modules;
  }

  final RawPlugin rawPlugin;
  final File file;
  final ValueNotifier<List<ModuleInfo>> _modules = ValueNotifier([]);

  ValueNotifier<List<ModuleInfo>> list() {
    return _modules;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _modules,
      builder: (context, List<ModuleInfo> modules, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 50, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: ExpansionTile(
              childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              title: Row(
                children: [
                  const Icon(
                    Icons.plumbing,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rawPlugin.getName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      PLUGINS.scan();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ],
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    return modules[index];
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}*/

/*class RawPlugin extends Struct {
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
*/
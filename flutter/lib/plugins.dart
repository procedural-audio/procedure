import 'package:flutter/material.dart';

import 'dart:io';

import 'patch/patch.dart';
import 'module/info.dart';

class Plugin {
  Plugin(this.name, this.version, this._modules);

  final String name;
  final int version;
  final ValueNotifier<List<ModuleInfo>> _modules;

  static Future<Plugin?> load(String path) async {
    List<ModuleInfo> modules = [];

    await Directory(path)
        .list(recursive: true)
        .where((item) => item.name.endsWith(".cmajormodule"))
        .forEach((file) async {
      var info = await ModuleInfo.load(file.path);
      if (info != null) {
        print("Loaded module ${file.name} at ${file.path}");
        modules.add(info);
      } else {
        print("Failed to load module: ${file.path}");
      }
    });

    return Plugin("Temp Plugin Name", 1, ValueNotifier(modules));
  }

  ValueNotifier<List<ModuleInfo>> modules() {
    return _modules;
  }
}

class Plugins {
  static final ValueNotifier<List<Plugin>> _plugins = ValueNotifier([]);

  static void scan(String path) async {
    print("Scanning plugins");

    var directory = Directory(path);

    List<Plugin> newPlugins = [];
    if (await directory.exists()) {
      var items = directory.list();
      await for (var item in items) {
        var plugin = await Plugin.load(item.path);
        if (plugin != null) {
          newPlugins.add(plugin);
        }
      }
    } else {
      print("Plugin directory doesn't exist");
    }

    _plugins.value = newPlugins;
  }

  static ValueNotifier<List<Plugin>> list() {
    return _plugins;
  }

  /*void reload(String path) async {
    print("Reloading plugin at $path");

    var newPlugin = await Plugin.load(path);

    if (newPlugin == null) {
      print("Failed to reload plugin at $path");
      return;
    }

    _plugins.value = _plugins.value.map((plugin) {
      if (plugin.name == newPlugin.name) {
        return newPlugin;
      } else {
        return plugin;
      }
    }).toList();
  }*/
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

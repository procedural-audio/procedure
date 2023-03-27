import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:math';
import 'dart:ffi';
import 'dart:io';

import 'settings.dart';
import 'module.dart';
import 'patch.dart';
import 'core.dart';

RawPlugins Function() _ffiCreatePlugins = core
    .lookup<NativeFunction<RawPlugins Function()>>("ffi_create_plugins")
    .asFunction();
RawPlugin Function(RawPlugins, Pointer<Utf8>) _ffiPluginsLoad = core
    .lookup<NativeFunction<RawPlugin Function(RawPlugins, Pointer<Utf8>)>>(
        "ffi_plugins_load")
    .asFunction();

Plugins PLUGINS = Plugins.platformDefault();

class RawPlugins extends Struct {
  @Int64()
  external int pointer;

  static RawPlugins create() {
    return _ffiCreatePlugins();
  }

  Plugin? load(String path) {
    var cPath = path.toNativeUtf8();
    var plugin = _ffiPluginsLoad(this, cPath);
    calloc.free(cPath);

    if (plugin.pointer != 0) {
      return Plugin(plugin);
    } else {
      return null;
    }
  }

  void remove(String path) {}
}

class Plugins extends StatelessWidget {
  Plugins(this.directory) {
    var pluginLoadDir = Directory(Settings2.pluginLoadDirectory());
    pluginLoadDir.listSync().forEach((e) => e.delete());

    scan();
  }

  final Directory directory;
  final ValueNotifier<List<Plugin>> _plugins = ValueNotifier([]);
  RawPlugins rawPlugin = RawPlugins.create();

  static Plugins platformDefault() {
    var path = "/Users/chasekanipe/Github/nodus/build/out/core/release/";
    var directory = Directory(path);
    return Plugins(directory);
  }

  void scan() async {
    print("Scanning plugins");

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
          var plugin = rawPlugin.load(item.path);

          if (plugin != null) {
            plugins.add(plugin);
          }
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _plugins,
      builder: (context, List<Plugin> plugins, child) {
        return ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: plugins.length,
          itemBuilder: (context, index) {
            return plugins[index];
          },
        );
      },
    );
  }
}

class Plugin extends StatelessWidget {
  Plugin(this.rawPlugin) {
    List<ModuleInfo> modules = [];

    int count = rawPlugin.getModuleCount();
    for (int i = 0; i < count; i++) {
      var rawModuleInfo = rawPlugin.getModuleInfo(i);
      modules.add(ModuleInfo.from(rawModuleInfo));
    }

    _modules.value = modules;
  }

  final RawPlugin rawPlugin;
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
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 50, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: ExpansionTile(
              childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              title: Text(
                rawPlugin.getName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
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

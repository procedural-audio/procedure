import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/project/browser.dart';

import 'info.dart';
import 'patch/patch.dart';
import '../plugins.dart';
import 'interface/ui.dart';

class Preset {
  Preset({required this.info, required this.patch, required this.interface});

  final PresetInfo info;
  final Patch patch;
  final ValueNotifier<UserInterface?> interface;

  static Preset from(PresetInfo info, List<Plugin> plugins) {
    return Preset(
      info: info,
      patch: Patch.from(info, plugins),
      interface: ValueNotifier(null),
    );
  }

  static Future<Preset?> load(PresetInfo info, List<Plugin> plugins) async {
    var patch = await Patch.load(info, plugins);
    if (patch != null) {
      var interface = await UserInterface.load(info);

      return Preset(
        info: info,
        patch: patch,
        interface: ValueNotifier(interface),
      );
    }

    return null;
  }

  static Preset blank(Directory projectDirectory, List<Plugin> plugins) {
    var directory = Directory(projectDirectory.path + "/presets/New Preset");
    var info = PresetInfo.blank(directory);
    return Preset(
      info: info,
      patch: Patch.from(info, plugins),
      interface: ValueNotifier(null)
    );
  }

  Future<void> save() async {
    print("Saving preset");
    await patch.save();
    await interface.value?.save();
  }
}

class PresetsBrowser extends StatelessWidget {
  PresetsBrowser({
    super.key,
    required this.directory,
    required this.presets,
    required this.onLoad,
    required this.onAddInterface,
    required this.onRemoveInterface,
  });

  final Directory directory;
  final ValueNotifier<List<PresetInfo>> presets;
  final ValueNotifier<Widget?> selectedItem = ValueNotifier(null);
  final void Function(PresetInfo) onLoad;
  final void Function(PresetInfo) onAddInterface;
  final void Function(PresetInfo) onRemoveInterface;

  void newPreset() async {
    print("New preset");
    var newName = "New Preset";
    var newPath = directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = "New Preset" + i.toString();
      newPath = directory.path + "/" + newName;
      i++;
    }

    var newInfo = PresetInfo(
      directory: Directory(newPath),
      hasInterface: false,
    );

    presets.value.add(newInfo);
    presets.notifyListeners();
  }

  void duplicatePreset(PresetInfo info) async {
    print("Duplicate preset");
    var newName = info.name + " (copy)";
    var newPath = info.directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = info.name + " (copy " + i.toString() + ")";
      newPath = info.directory.path + "/" + newName;
      i++;
    }

    await Process.run("cp", ["-r", info.directory.path, newPath]);
    var newInfo = await PresetInfo.load(Directory(newPath));

    if (newInfo != null) {
      presets.value.add(newInfo);
      presets.notifyListeners();
    }
  }

  void addInterface(PresetInfo info) {
    onAddInterface(info);
  }

  void removeInterface(PresetInfo info) {
    onRemoveInterface(info);
  }

  void deletePreset(PresetInfo info) async {
    print("Removing project");
    await info.directory.delete(recursive: true);
    presets.value.remove(info);
    presets.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      height: 450,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(30, 30, 30, 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      child: ValueListenableBuilder<List<PresetInfo>>(
        valueListenable: presets,
        builder: (context, presets, child) {
          List<PresetItem> items = presets
              .map((info) => PresetItem(
                    info: info,
                    onLoad: () {
                      onLoad(info);
                    },
                    onDuplicate: () {
                      duplicatePreset(info);
                    },
                    onAddInterface: () {
                      addInterface(info);
                    },
                    onRemoveInterface: () {
                      removeInterface(info);
                    },
                    onDelete: () {
                      deletePreset(info);
                    },
                  ))
              .toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: items,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      newPreset();
                    },
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}

class PresetItem extends StatefulWidget {
  const PresetItem({
    super.key,
    required this.info,
    required this.onLoad,
    required this.onDuplicate,
    required this.onAddInterface,
    required this.onRemoveInterface,
    required this.onDelete,
  });

  final PresetInfo info;
  final void Function() onLoad;
  final void Function() onDuplicate;
  final void Function() onAddInterface;
  final void Function() onRemoveInterface;
  final void Function() onDelete;

  @override
  State<PresetItem> createState() => _PresetItem();
}

class _PresetItem extends State<PresetItem> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (e) {
        setState(() {
          hovering = false;
        });
      },
      child: GestureDetector(
        /*onDoubleTap: () {
          widget.onLoad();
        },*/
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            height: 30,
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            decoration: BoxDecoration(
              color: hovering
                  ? const Color.fromRGBO(40, 40, 40, 1.0)
                  : const Color.fromRGBO(30, 30, 30, 1.0),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Column(children: <Widget>[
              SizedBox(
                height: 30,
                child: Row(
                  children: [
                    Builder(
                        builder: (context) {
                          if (widget.info.hasInterface) {
                            return const Icon(
                              Icons.display_settings,
                              size: 16,
                              color: Colors.green,
                            );
                          } else {
                            return const Icon(
                              Icons.cable,
                              size: 16,
                              color: Colors.blue,
                            );
                          }
                        }),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.info.name,
                        style: TextStyle(
                          color: hovering
                              ? Colors.white
                              : const Color.fromRGBO(200, 200, 200, 1.0),
                        ),
                      ),
                    ),
                    MoreDropdown(
                      items: [
                        "Load Preset",
                        "Rename Preset",
                        "Duplicate Preset",
                        widget.info.hasInterface ? "Remove Interface" : "Add Interface",
                        "Delete Preset"
                      ],
                      onAction: (s) {
                        if (s == "Load Preset") {
                          widget.onLoad();
                        } else if (s == "Rename Preset") {
                          print("Should rename here");
                        } else if (s == "Duplicate Preset") {
                          widget.onDuplicate();
                        } else if (s == "Add Interface") {
                          widget.onAddInterface();
                        } else if (s == "Remove Interface") {
                          widget.onRemoveInterface();
                        } else if (s == "Delete Preset") {
                          widget.onDelete();
                        }
                      },
                      color: const Color.fromRGBO(40, 40, 40, 1.0),
                      hoverColor: const Color.fromRGBO(30, 30, 30, 1.0),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

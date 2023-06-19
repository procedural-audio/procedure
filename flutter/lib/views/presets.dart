import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/ui/ui.dart';
import 'package:metasampler/views/projects.dart';

import '../config.dart';
import '../patch.dart';
import '../views/info.dart';

class PresetInfo {
  PresetInfo({
    required this.directory,
    required this.name,
    required this.description,
    required this.hasInterface,
  });

  final Directory directory;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
  final ValueNotifier<bool> hasInterface;

  static PresetInfo blank(Directory directory) {
    return PresetInfo(
      directory: Directory(directory.path + "/New Patch"),
      name: ValueNotifier("New Patch"),
      description: ValueNotifier("New patch description"),
      hasInterface: ValueNotifier(false),
    );
  }

  static Future<PresetInfo?> load(Directory directory) async {
    if (await directory.exists()) {
      File file = File(directory.path + "/preset.json");
      if (await file.exists()) {
        var contents = await file.readAsString();
        var json = jsonDecode(contents);

        bool interfaceExists = await File(directory.path + "/interface.json").exists();

        return PresetInfo(
          directory: directory,
          name: ValueNotifier(json["name"] ?? "Some Name"),
          description: ValueNotifier(json["description"] ?? "Some Description"),
          hasInterface: ValueNotifier(interfaceExists),
        );
      }
    }

    return null;
  }

  Future<bool> save() async {
    if (!await directory.exists()) {
      await directory.create();
    }

    print("Saving patch info");

    File file = File(directory.path + "/preset.json");
    await file.writeAsString(jsonEncode({
      "name": name.value,
      "description": description.value,
    }));

    return true;
  }
}

class PresetsView extends StatelessWidget {
  PresetsView({
    required this.directory,
    required this.presets,
    required this.onLoad,
  });

  final Directory directory;
  final ValueNotifier<List<PresetInfo>> presets;
  final ValueNotifier<Widget?> selectedItem = ValueNotifier(null);
  final void Function(PresetInfo) onLoad;

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
      name: ValueNotifier(newName),
      description: ValueNotifier("A new project description"),
      hasInterface: ValueNotifier(false),
    );

    await newInfo.save();

    presets.value.add(newInfo);
    presets.notifyListeners();
  }

  void duplicatePreset(PresetInfo info) async {
    print("Duplicate preset");
    var newName = info.name.value + " (copy)";
    var newPath = info.directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = info.name.value + " (copy " + i.toString() + ")";
      newPath = info.directory.path + "/" + newName;
      i++;
    }

    await Process.run("cp", ["-r", info.directory.path, newPath]);
    var newInfo = await PresetInfo.load(Directory(newPath));

    if (newInfo != null) {
      newInfo.name.value = newName;
      await newInfo.save();

      presets.value.add(newInfo);
      presets.notifyListeners();
    }
  }

  void addInterface(PresetInfo info) async {
    var newInterface = UserInterface(info);
    await newInterface.save();
    print("Should actually load interface within project here");
    info.hasInterface.value = true;
  }

  void removeInterface(PresetInfo info) async {
    info.hasInterface.value = false;
    File(info.directory.path + "/interface.json").delete();
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
              List<PresetItem> items = 
                 presets 
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
                ]
              );
        },
      ),
    );
  }
}

/*class InterfaceItem extends StatelessWidget {
  InterfaceItem({
    required this.info,
    required this.selectedItem,
  });

  final InterfaceInfo info;
  final ValueNotifier<Widget?> selectedItem;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PresetInfo>>(
      valueListenable: info.patches,
      builder: (context, patches, child) {
        return PresetsViewItem(
          name: info.name,
          expandable: true,
          icon: const Icon(
            Icons.display_settings,
            size: 18,
            color: Colors.green,
          ),
          onTap: () {
            if (selectedItem.value == this) {
              selectedItem.value = null;
            } else {
              selectedItem.value = this;
            }
          },
          children: patches
              .map(
                (info) => Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color.fromRGBO(60, 60, 60, 1.0),
                      ),
                      Expanded(
                        child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                          child: GraphItem(
                          info,
                          selectedItem,
                        ),
                      ),
                      ),
                    ]
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}*/

/*class ItemAdd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 24,
      child: GestureDetector(
        onTap: () {
          print("Add");
        },
        child: const Icon(
          Icons.add,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
}*/

class PresetItem extends StatefulWidget {
  PresetItem({
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
        onDoubleTap: () {
          widget.onLoad();
        },
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
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: widget.info.hasInterface,
                        builder: (context, hasInterface, child) {
                          if (hasInterface) {
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
                        }
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.info.name,
                          builder: (context, name, child) {
                            return Text(
                              name,
                              style: TextStyle(
                                color: hovering
                                  ? Colors.white
                                  : const Color.fromRGBO(200, 200, 200, 1.0),
                              ),
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: widget.info.hasInterface,
                        builder: (context, hasInterface, child) {
                          return MoreDropdown(
                            items: [
                              "Load Preset",
                              "Rename Preset",
                              "Duplicate Preset",
                              hasInterface ? "Remove Interface" : "Add Interface",
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
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

class PresetDirectory {
  final String name;
  final String path;
  final List<PresetInfo> presets;

  PresetDirectory(
      {required this.name, required this.path, required this.presets});
}

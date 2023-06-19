import 'dart:io';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../config.dart';
import '../patch.dart';
import '../ui/common.dart';
import '../views/info.dart';

class PresetsView extends StatelessWidget {
  PresetsView({
    required this.patches,
    required this.interfaces,
    required this.onLoad,
  });

  final ValueNotifier<List<PatchInfo>> patches;
  final ValueNotifier<List<InterfaceInfo>> interfaces;

  final ValueNotifier<Widget?> selectedItem = ValueNotifier(null);
  final void Function(PatchInfo, InterfaceInfo?) onLoad;

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
      child: ValueListenableBuilder<List<PatchInfo>>(
        valueListenable: patches,
        builder: (context, patches, child) {
          return ValueListenableBuilder<List<InterfaceInfo>>(
            valueListenable: interfaces,
            builder: (context, interfaces, child) {
              List<Widget> items = <Widget>[] +
                  interfaces
                      .map((e) => InterfaceItem(
                            info: e,
                            selectedItem: selectedItem,
                          ))
                      .toList() +
                  patches
                      .map((info) => GraphItem(
                            info,
                            selectedItem,
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
                        icon: Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          print("Stuff");
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.create_new_folder,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          print("Stuff");
                        },
                      ),
                    ],
                  )
                ]
              );
            }
          );
        },
      ),
    );
  }
}

class InterfaceItem extends StatelessWidget {
  InterfaceItem({
    required this.info,
    required this.selectedItem,
  });

  final InterfaceInfo info;
  final ValueNotifier<Widget?> selectedItem;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PatchInfo>>(
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
}

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

class GraphItem extends StatelessWidget {
  GraphItem(this.info, this.selectedItem);

  final PatchInfo info;
  final ValueNotifier<Widget?> selectedItem;

  @override
  Widget build(BuildContext context) {
    return PresetsViewItem(
      name: info.name,
      height: 30,
      expandable: false,
      icon: const Icon(
        Icons.cable,
        size: 16,
        color: Colors.blue,
      ),
      onTap: () {
        if (selectedItem.value == this) {
          selectedItem.value = null;
        } else {
          selectedItem.value = this;
        }
      },
      children: const [],
    );
  }
}

/*class CategoryItem extends StatelessWidget {
  CategoryItem(this.text, {required this.selectedItem});

  final String text;
  final ValueNotifier<Widget?> selectedItem;

  @override
  Widget build(BuildContext context) {
    return PresetsViewItem(
      text: text,
      icon: const Icon(
        Icons.folder,
        size: 18,
        color: Colors.blue,
      ),
      expandable: true,
      onTap: () {
        if (selectedItem.value == this) {
          selectedItem.value = null;
        } else {
          selectedItem.value = this;
        }
      },
      children: const [],
    );
  }
}*/

/*class PresetItem extends StatelessWidget {
  PresetItem(this.text, {required this.selectedItem});

  final String text;
  final ValueNotifier<Widget?> selectedItem;

  @override
  Widget build(BuildContext context) {
    return PresetsViewItem(
      text: text,
      expandable: false,
      icon: const Icon(
        Icons.functions,
        size: 18,
        color: Colors.red,
      ),
      onTap: () {
        if (selectedItem.value == this) {
          selectedItem.value = null;
        } else {
          selectedItem.value = this;
        }
      },
      children: const [],
    );
  }
}*/

class PresetsViewItem extends StatefulWidget {
  PresetsViewItem(
      {required this.name,
      this.height = 30,
      required this.icon,
      required this.expandable,
      required this.onTap,
      required this.children});

  final ValueNotifier<String> name;
  final Icon icon;
  final double height;
  final bool expandable;
  final void Function() onTap;
  final List<Widget> children;

  @override
  State<StatefulWidget> createState() => _PresetsViewItem();
}

class _PresetsViewItem extends State<PresetsViewItem> {
  bool hovering = false;
  bool expanded = false;

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
        onTap: () {
          widget.onTap();
        },
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            height: expanded ? null : widget.height,
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            decoration: BoxDecoration(
              color: ((hovering && !expanded)
                  ? const Color.fromRGBO(40, 40, 40, 1.0)
                  : const Color.fromRGBO(30, 30, 30, 1.0)),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Column(
              children: <Widget>[
                    SizedBox(
                      height: widget.height,
                      child: Row(
                        children: [
                          widget.icon,
                          const SizedBox(width: 10),
                          Expanded(
                              child: ValueListenableBuilder<String>(
                            valueListenable: widget.name,
                            builder: (context, name, child) {
                              return Text(
                                name,
                                style: TextStyle(
                                  color: hovering
                                      ? Colors.white
                                      : const Color.fromRGBO(
                                          200, 200, 200, 1.0),
                                ),
                              );
                            },
                          )),
                          Visibility(
                            visible: widget.expandable,
                            child: GestureDetector(
                              onTap: () {
                                if (widget.expandable) {
                                  setState(() {
                                    expanded = !expanded;
                                  });
                                }
                              },
                              child: SizedBox(
                                width: 35,
                                height: 35,
                                child: Icon(
                                  expanded
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] +
                  (expanded ? widget.children : []),
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

@JsonSerializable()
class PresetInfo {
  PresetInfo(this.name, this.file);

  final String name;
  final File file;

  //String description = "# Introduction\nHere is a paragraph that can go below the title. It is here to fill some space.\n";
  //int rating = -1;

  /*PresetInfo.fromJson(Map<String, dynamic> json, String dirPath) {
    name = json['name'];
    description = json['description'];
    path = dirPath;
  }*/

  /*Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
  };*/
}

bool createDirectory(String name, String instPath) {
  if (name == "") {
    return false;
  }

  for (var dir in presetDirs) {
    if (dir.name == name) {
      return false;
    }
  }

  Directory dir = Directory(instPath + "/presets/" + name);

  presetDirs.add(PresetDirectory(name: name, path: dir.path, presets: []));

  dir.create(recursive: true);

  // setState(() {});

  return true;
}

bool createPreset(String name, String selectedFolder) {
  if (name == "") {
    return false;
  }

  for (var dir in presetDirs) {
    for (var preset in dir.presets) {
      if (preset.name == name) {
        return false;
      }
    }
  }

  for (int i = 0; i < presetDirs.length; i++) {
    if (presetDirs[i].name == selectedFolder) {
      File file = File(presetDirs[i].path + "/" + name);
      presetDirs[i].presets.add(PresetInfo(name, file));
      file.create(recursive: true);
    }
  }

  // setState(() {});

  return true;
}

void duplicatePreset(PresetInfo info) {
  var index = 2;
  var parentPath = info.file.parent.path;
  var newName = info.name + " (" + index.toString() + ")";
  var newPath = parentPath + "/" + newName;

  // BUG: Should use name instead of path
  while (File(newPath).existsSync()) {
    newName = info.name + " (" + index.toString() + ")";
    newPath = parentPath + "/" + newName;
    index += 1;
  }

  for (int i = 0; i < presetDirs.length; i++) {
    if (presetDirs[i].name == info.file.parent.path.split("/").last) {
      for (int j = 0; j < presetDirs[i].presets.length; j++) {
        if (presetDirs[i].presets[j].name == info.name) {
          presetDirs[i]
              .presets
              .insert(j + 1, PresetInfo(newName, File(newPath)));
          break;
        }
      }
    }
  }

  info.file.copy(newPath);

  // setState(() {});
}

bool renamePreset(PresetInfo info, String name) {
  var newPath = info.file.parent.path + "/" + name;

  if (info.name == name) {
    return true;
  }

  for (var dir in presetDirs) {
    for (var preset in dir.presets) {
      if (preset.name == name) {
        return false;
      }
    }
  }

  for (int i = 0; i < presetDirs.length; i++) {
    for (int j = 0; j < presetDirs[i].presets.length; j++) {
      if (presetDirs[i].presets[j].file.path == info.file.path) {
        presetDirs[i].presets[j] = PresetInfo(name, File(newPath));
      }
    }
  }

  info.file.rename(newPath);

  // setState(() {});

  return true;
}

void removePreset(PresetInfo info) {
  for (int i = 0; i < presetDirs.length; i++) {
    for (int j = 0; j < presetDirs[i].presets.length; j++) {
      if (presetDirs[i].presets[j].file.path == info.file.path) {
        presetDirs[i].presets.removeAt(j);
      }
    }
  }

  info.file.delete();

  // setState(() {});
}

bool movePreset(String presetName, String categoryName) {
  bool validMove = false;

  for (var dir in presetDirs) {
    if (dir.name == categoryName) {
      validMove = true;
    }
  }

  if (!validMove) {
    print("Failed to find destination directory");
    return false;
  }

  for (int i = 0; i < presetDirs.length; i++) {
    for (int j = 0; j < presetDirs[i].presets.length; j++) {
      if (presetDirs[i].presets[j].name == presetName) {
        if (presetDirs[i].name == categoryName) {
          return true;
        }

        var oldFile = presetDirs[i].presets[j].file;
        var newPath =
            oldFile.parent.parent.path + "/" + categoryName + "/" + presetName;
        oldFile.copySync(newPath);
        oldFile.delete();

        presetDirs[i].presets.removeAt(j);

        var newPreset = PresetInfo(presetName, File(newPath));

        for (int k = 0; k < presetDirs.length; k++) {
          if (presetDirs[k].name == categoryName) {
            presetDirs[k].presets.add(newPreset);
          }
        }

        // setState(() {});
        return true;
      }
    }
  }

  // setState(() {});

  return true;
}

bool renameDirectory(String name, String newName) {
  if (name == newName) {
    return true;
  }

  for (var dir in presetDirs) {
    if (dir.name == newName) {
      return false;
    }
  }

  for (int i = 0; i < presetDirs.length; i++) {
    if (presetDirs[i].name == name) {
      String newPath =
          Directory(presetDirs[i].path).parent.path + "/" + newName;

      var newDir = PresetDirectory(
          name: newName, path: newPath, presets: presetDirs[i].presets);

      Directory(presetDirs[i].path).rename(newPath);
      presetDirs[i] = newDir;
    }
  }

  // setState(() {});

  return true;
}

void removeDirectory(String name) {
  for (int i = 0; i < presetDirs.length; i++) {
    if (presetDirs[i].name == name) {
      Directory(presetDirs[i].path).delete(recursive: true);
      presetDirs.removeAt(i);
    }
  }

  // setState(() {});
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'settings.dart';

import '../host.dart';
import '../config.dart';

class PresetsView extends StatelessWidget {
  PresetsView(this.host);

  Host host;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    UserInterfaceItem(
                      host,
                      text: "Interface 1",
                      children: [
                        GraphItem(host, "Graph 1"),
                        GraphItem(host, "Graph 2"),
                        GraphItem(host, "Graph 3"),
                        GraphItem(host, "Graph 4"),
                      ],
                    ),
                    UserInterfaceItem(
                      host,
                      text: "Interface 2",
                      children: [
                        GraphItem(host, "Graph 5"),
                        GraphItem(host, "Graph 6"),
                      ],
                    ),
                    GraphItem(host, "Graph 1"),
                    GraphItem(host, "Graph 2"),

                    /*CategoryItem("Category 1"),
                    CategoryItem("Category 2"),*/

                    /*PresetItem("Preset 1"),
                    PresetItem("Preset 2"),
                    PresetItem("Preset 3"),
                    PresetItem("Preset 4"),*/
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(50, 50, 50, 1.0),
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UserInterfaceItem extends StatelessWidget {
  UserInterfaceItem(this.host, {required this.text, required this.children});

  final String text;
  final Host host;
  final List<GraphItem> children;

  @override
  Widget build(BuildContext context) {
    return PresetsViewItem(
        text: text,
        expandable: true,
        icon: const Icon(
          Icons.display_settings,
          size: 18,
          color: Colors.green,
        ),
        onTap: () {},
        children: // <Widget>[] +
            children
                .map(
                  (e) => GraphItem(host, e.text, isDense: true),
                )
                .toList() /*+
          <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ItemAdd(),
                ItemAdd(),
                ItemAdd(),
              ],
            ),
          ],*/
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
  GraphItem(this.host, this.text, {this.isDense = false});

  final Host host;
  final String text;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return PresetsViewItem(
      text: text,
      height: isDense ? 30 : 35,
      expandable: false,
      padding:
          isDense ? EdgeInsets.zero : const EdgeInsets.fromLTRB(0, 0, 0, 4),
      icon: const Icon(Icons.cable, size: 18, color: Colors.blue),
      onTap: () {
        print("Graph preset tap");
      },
      children: const [],
    );
  }
}

class CategoryItem extends StatelessWidget {
  CategoryItem(this.text);

  final String text;

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
      onTap: () {},
      children: const [],
    );
  }
}

class PresetItem extends StatelessWidget {
  PresetItem(this.text);

  final String text;

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
      onTap: () {},
      children: const [],
    );
  }
}

class PresetsViewItem extends StatefulWidget {
  PresetsViewItem(
      {required this.text,
      this.height = 35,
      required this.icon,
      required this.expandable,
      this.padding = const EdgeInsets.fromLTRB(0, 0, 0, 4),
      required this.onTap,
      required this.children});

  final String text;
  final Icon icon;
  final double height;
  final bool expandable;
  final EdgeInsets padding;
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
          print("Selecte stuff");
        },
        child: Padding(
          padding: widget.padding,
          child: Container(
            height: expanded ? null : widget.height,
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            decoration: BoxDecoration(
              color: ((hovering && !expanded)
                  ? const Color.fromRGBO(60, 60, 60, 1.0)
                  : const Color.fromRGBO(50, 50, 50, 1.0)),
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
                            child: Text(
                              widget.text,
                              style: TextStyle(
                                color: hovering
                                    ? Colors.white
                                    : const Color.fromRGBO(200, 200, 200, 1.0),
                              ),
                            ),
                          ),
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

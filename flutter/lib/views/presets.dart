import 'package:metasampler/ui/layout.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../host.dart';
import '../main.dart';
import 'settings.dart';

import '../config.dart';

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

  presetDirs
      .add(PresetDirectory(name: name, path: dir.path, presets: []));

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
          presetDirs[i].presets
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
        var newPath = oldFile.parent.parent.path +
            "/" +
            categoryName +
            "/" +
            presetName;
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
          name: newName,
          path: newPath,
          presets: presetDirs[i].presets);

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

class PresetsView extends StatefulWidget {
  PresetsView(this.host);

  Host host;

  @override
  State<PresetsView> createState() => _PresetsView();
}

class _PresetsView extends State<PresetsView> {
  int type = 0;
  String selectedFolder = "All";
  bool hovering = false;
  bool shouldCreatePreset = false;
  bool shouldCreateDirectory = false;
  String selectedPreset = "";
  bool locked = true;

  ValueNotifier<int> notifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        List<Widget> dirWidgets = [];
        List<Widget> presetWidgets = [];

        dirWidgets.add(PresetDivider());
        presetWidgets.add(PresetDivider());

        for (var dir in presetDirs) {
          dirWidgets.add(PresetDirectoryWidget(
            notifier: notifier,
            presetDir: dir,
            onTap: () {
              setState(() {
                if (selectedFolder == dir.name) {
                  selectedFolder = "All";
                } else {
                  selectedFolder = dir.name;
                }
                selectedPreset = "";
              });
            },
            selected: selectedFolder,
            locked: locked,
          ));

          dirWidgets.add(PresetDivider());

          for (var preset in dir.presets) {
            if (selectedFolder == "All" ||
                selectedFolder == preset.file.parent.path.split("/").last) {
              presetWidgets.add(PresetEntryWidget(
                widget.host,
                notifier: notifier,
                info: preset,
                selected: selectedPreset,
                onTap: () {
                  if (selectedPreset == preset.name) {
                    setState(() {
                      selectedPreset = "";
                    });
                  } else {
                    setState(() {
                      selectedPreset = preset.name;
                    });
                  }
                },
                locked: locked,
              ));

              presetWidgets.add(PresetDivider());
            }
          }
        }

        if (!locked) {
          if (shouldCreateDirectory) {
            shouldCreateDirectory = false;
            dirWidgets.add(PresetDirectoryNewWidget(widget.host, notifier: notifier));
          } else {
            dirWidgets.add(PresetAddWidget(onClick: () {
              setState(() {
                shouldCreateDirectory = true;
              });
            }));
          }

          if (shouldCreatePreset) {
            shouldCreatePreset = false;
            presetWidgets.add(PresetNewWidget(selectedFolder: selectedFolder, notifier: notifier));
          } else {
            presetWidgets.add(PresetAddWidget(onClick: () {
              setState(() {
                shouldCreatePreset = true;
              });
            }));
          }
        }

        return Stack(
          children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: ListView(
                        children: dirWidgets,
                      )
                    )
                  ),
                  Container(
                    width: 2,
                    color: const Color.fromRGBO(60, 60, 60, 1.0),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: ListView(
                        children: presetWidgets,
                      )
                    )
                  )
                ],
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: locked
                      ? const Icon(Icons.lock)
                      : const Icon(Icons.lock_open),
                  color: locked ? Colors.white70 : Colors.white,
                  iconSize: 20,
                  onPressed: () {
                    setState(() {
                      locked = !locked;
                    });
                  },
                ),
                decoration: BoxDecoration(
                  color: MyTheme.grey50,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(10)),
                ),
              )
            )
          ]
        );
      }
    );

    /*const double width = 450;

    return Container(
      width: width,
      height: expanded ? 500 : 35,
      child: Container(
        height: expanded ? 500 : 35,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 10,
              top: 35,
              child: Container(
                width: 170 + 40,
                height: 450,
                child: ListView(
                  children: dirWidgets,
                ),
                decoration: BoxDecoration(color: MyTheme.grey40),
              ),
            ),
            Positioned(
              left: 220 - 30 + 40,
              top: 35,
              child: Container(
                width: 320 + 50 - 20 - 40,
                height: 450,
                child: ListView(
                  children: presetWidgets,
                ),
                decoration: BoxDecoration(color: MyTheme.grey40),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: expanded
                  ? Container(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: locked
                            ? const Icon(Icons.lock)
                            : const Icon(Icons.lock_open),
                        color: locked ? Colors.white70 : Colors.white,
                        iconSize: 20,
                        onPressed: () {
                          setState(() {
                            locked = !locked;
                          });
                        },
                      ),
                      decoration: BoxDecoration(
                        color: MyTheme.grey50,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                    )
                  : Container(),
            )
          ],
        ),
        decoration: BoxDecoration(
          color: MyTheme.grey50,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
      ),
      decoration: BoxDecoration(
        color: hovering ? MyTheme.grey40 : MyTheme.grey30,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    );*/
  }
}

class PresetDirectoryWidget extends StatefulWidget {
  final PresetDirectory presetDir;
  final Function() onTap;
  final String selected;
  final bool locked;

  ValueNotifier<int> notifier;

  PresetDirectoryWidget(
      {required this.presetDir,
      required this.onTap,
      required this.selected,
      required this.locked,
      required this.notifier})
      : super(key: UniqueKey());

  @override
  State<PresetDirectoryWidget> createState() => _PresetDirectoryWidgetState();
}

class _PresetDirectoryWidgetState extends State<PresetDirectoryWidget> {
  bool hovering = false;
  bool editing = false;
  bool editFailed = false;

  String editingText = "";

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        opaque: false,
        onEnter: (event) {
          setState(() {
            hovering = true;
          });
        },
        onExit: (event) {
          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onTap: () {
            widget.onTap();
          },
          behavior: HitTestBehavior.deferToChild,
          child: DragTarget(
            onWillAccept: (data) {
              if (data.runtimeType == String) {
                return true;
              } else {
                return false;
              }
            },
            onAccept: (data) {
              movePreset(data as String, widget.presetDir.name);

              widget.notifier.notifyListeners();
            },
            builder: (context, List<Object?> candidateData, rejectedData) {
              return Container(
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: widget.selected == widget.presetDir.name
                      ? const Color.fromRGBO(80, 80, 80, 1.0)
                      : (hovering ? const Color.fromRGBO(70, 70, 70, 1.0): const Color.fromRGBO(60, 60, 60, 1.0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 40,
                      child: Icon(
                        Icons.folder,
                        color: Colors.blueAccent,
                        size: 18)),
                    Expanded(
                      child: Visibility(
                        visible: !editing,
                        child: Text(
                          widget.presetDir.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                        )
                      )
                    ),
                    Expanded(
                      child: Visibility(
                        visible: editing,
                        child: Container(
                          height: 24,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: MyTheme.grey50,
                            border: Border.all(
                              color: editFailed ? Colors.red : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: EditableText(
                              controller: TextEditingController.fromValue(
                                  TextEditingValue(text: editingText)),
                              onChanged: (text) {
                                editingText = text;
                              },
                              onSubmitted: (text) {
                                if (renameDirectory(widget.presetDir.name, text)) {
                                  setState(() {
                                    editing = false;
                                    editFailed = false;
                                  });
                                } else {
                                  setState(() {
                                    editFailed = true;
                                  });
                                }

                                widget.notifier.notifyListeners();
                              },
                              focusNode: FocusNode(),
                              cursorColor: Colors.blue,
                              backgroundCursorColor: Colors.blue,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 14,
                                  color: Colors.white,
                                  decoration: TextDecoration.none))))),
                  ]
                )
              );
              /*return Stack(children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  height: 35,
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.centerLeft,

                      /* Static name text */
                      child: !editing
                          ? Text(
                              widget.presetDir.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300),
                            )
                          :

                          /* Editable name text */
                          Expanded(
                            child: Container(
                              width: 240,
                              height: 24,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: MyTheme.grey50,
                                border: Border.all(
                                  color: editFailed ? Colors.red : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: EditableText(
                                  controller: TextEditingController.fromValue(
                                      TextEditingValue(text: editingText)),
                                  onChanged: (text) {
                                    editingText = text;
                                  },
                                  onSubmitted: (text) {
                                    if (renameDirectory(widget.presetDir.name, text)) {
                                      setState(() {
                                        editing = false;
                                        editFailed = false;
                                      });
                                    } else {
                                      setState(() {
                                        editFailed = true;
                                      });
                                    }

                                    widget.notifier.notifyListeners();
                                  },
                                  focusNode: FocusNode(),
                                  cursorColor: Colors.blue,
                                  backgroundCursorColor: Colors.blue,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                      color: Colors.white,
                                      decoration: TextDecoration.none))))),
                    Align(
                      alignment: Alignment.centerRight,
                      child: !editing
                          ? Visibility(
                              visible: hovering && !widget.locked,
                              child: Container(
                                width: 80,
                                child: Row(children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.white,
                                    iconSize: 16,
                                    onPressed: () {
                                      setState(() {
                                        editing = true;
                                        editingText = widget.presetDir.name;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.white,
                                    iconSize: 16,
                                    onPressed: () {
                                      removeDirectory(widget.presetDir.name);

                                      widget.notifier.notifyListeners();
                                    },
                                  )
                                ]),
                              ))
                          : Container(
                              width: 80,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    color: Colors.white,
                                    iconSize: 16,
                                    onPressed: () {
                                      if (renameDirectory(widget.presetDir.name, editingText)) {
                                        setState(() {
                                          editing = false;
                                          editFailed = false;
                                        });
                                      } else {
                                        setState(() {
                                          editFailed = true;
                                        });
                                      }

                                      widget.notifier.notifyListeners();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel),
                                    color: Colors.white,
                                    iconSize: 16,
                                    onPressed: () {
                                      setState(() {
                                        editing = false;
                                        editFailed = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                    )
                  ]),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    color: widget.selected == widget.presetDir.name
                        ? const Color.fromRGBO(80, 80, 80, 1.0)
                        : (hovering ? const Color.fromRGBO(70, 70, 70, 1.0): const Color.fromRGBO(60, 60, 60, 1.0)),
                  ),
                ),
                Container(
                  height: 44,
                  width: 120,
                  child: DragTarget(
                    builder: (context, List<Object?> candidateData, rejectedData) {
                      return Container();
                    },
                    onWillAccept: (data) {
                      if (data.runtimeType == String) {
                        return true;
                      } else {
                        return false;
                      }
                    },
                    onAccept: (data) {
                      movePreset(data as String, widget.presetDir.name);

                      widget.notifier.notifyListeners();
                    },
                  ),
                ),
              ]);*/
            },
          ),
        ));
  }
}

/*class PresetDirectoryWidget extends StatefulWidget {
  final PresetDirectory presetDir;
  final Function() onTap;
  final String selected;
  bool editing = false;

  PresetDirectoryWidget({required this.presetDir, required this.onTap, required this.selected}) : super(key: UniqueKey());

  @override
  State<PresetDirectoryWidget> createState() => _PresetDirectoryWidgetState(presetDir: presetDir, onTap: onTap, selected: selected);
}

class _PresetDirectoryWidgetState extends State<PresetDirectoryWidget> {
  bool hovering = false;
  final PresetDirectory presetDir;
  final Function() onTap;
  final String selected;

  _PresetDirectoryWidgetState({required this.presetDir, required this.onTap, required this.selected});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (event) {
        setState(() {
          hovering = false;
        });
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          height: 44,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  presetDir.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
              Visibility(
                visible: hovering,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 80,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.white,
                          iconSize: 16,
                          onPressed: () {
                            setState(() {
                              
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.white,
                          iconSize: 16,
                          onPressed: () {
                            setState(() {
                              globals.window.presetsView.refresh();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )
              )
            ]
          ),
          decoration: BoxDecoration(
            color: (selected == presetDir.name) ? MyTheme.grey70 : (hovering ? MyTheme.grey60 : MyTheme.grey50)
          ),
        ),
      ),
    );
  }
}*/

class PresetDirectoryNewWidget extends StatefulWidget {
  PresetDirectoryNewWidget(this.host, {required this.notifier}) : super(key: UniqueKey());

  ValueNotifier<int> notifier;
  Host host;

  @override
  State<PresetDirectoryNewWidget> createState() =>
      _PresetDirectoryNewWidgetState();
}

class _PresetDirectoryNewWidgetState extends State<PresetDirectoryNewWidget> {
  String editingText = "";

  _PresetDirectoryNewWidgetState();

  bool hovering = false;
  bool editFailed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: MouseRegion(
          opaque: false,
          onEnter: (event) {
            setState(() {
              hovering = true;
            });
          },
          onExit: (event) {
            setState(() {
              hovering = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            height: 44,
            child: Stack(children: [
              Align(
                alignment: Alignment.centerLeft,

                /* Static name text */
                /* Editable name text */
                child: Container(
                  width: 120,
                  height: 26,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MyTheme.grey50,
                    border: Border.all(
                      color: editFailed ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: EditableText(
                      controller: TextEditingController.fromValue(
                          TextEditingValue(text: editingText)),
                      onChanged: (text) {
                        editingText = text;
                      },
                      onSubmitted: (text) {
                        if (createDirectory(text, widget.host.globals.instrument.path)) {
                          setState(() {});
                          // Nothing
                        } else {
                          setState(() {
                            editFailed = true;
                          });
                        }

                        widget.notifier.notifyListeners();
                      },
                      focusNode: FocusNode(),
                      cursorColor: Colors.blue,
                      backgroundCursorColor: Colors.blue,
                      maxLines: 1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: Colors.white,
                          decoration: TextDecoration.none)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 80,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.save),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          if (createDirectory(editingText, widget.host.globals.instrument.path)) {
                            setState(() {});
                            // Nothing
                          } else {
                            setState(() {
                              editFailed = true;
                            });
                          }

                          widget.notifier.notifyListeners();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          setState(() {});
                          widget.notifier.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ),
              )
            ]),
            decoration: BoxDecoration(
                color: hovering ? MyTheme.grey60 : MyTheme.grey50),
          ),
        ));
  }
}

class PresetNewWidget extends StatefulWidget {
  PresetNewWidget({required this.selectedFolder, required this.notifier}) : super(key: UniqueKey());

  String selectedFolder;
  ValueNotifier<int> notifier;

  @override
  State<PresetNewWidget> createState() => _PresetNewWidgetState();
}

class _PresetNewWidgetState extends State<PresetNewWidget> {
  String editingText = "Untitled Preset";

  _PresetNewWidgetState();

  bool hovering = false;
  bool editFailed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: MouseRegion(
          opaque: false,
          onEnter: (event) {
            setState(() {
              hovering = true;
            });
          },
          onExit: (event) {
            setState(() {
              hovering = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            height: 44,
            child: Stack(children: [
              Align(
                alignment: Alignment.centerLeft,

                /* Static name text */
                /* Editable name text */
                child: Container(
                  width: 210,
                  height: 26,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MyTheme.grey50,
                    border: Border.all(
                      color: editFailed ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: EditableText(
                      controller: TextEditingController.fromValue(
                          TextEditingValue(text: editingText)),
                      onChanged: (text) {
                        editingText = text;
                      },
                      onSubmitted: (text) {
                        if (createPreset(text, widget.selectedFolder)) {
                          // Nothing
                        } else {
                          setState(() {
                            editFailed = true;
                          });
                        }

                        widget.notifier.notifyListeners();
                      },
                      focusNode: FocusNode(),
                      cursorColor: Colors.blue,
                      backgroundCursorColor: Colors.blue,
                      maxLines: 1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: Colors.white,
                          decoration: TextDecoration.none)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 80,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.save),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          if (createPreset(editingText, widget.selectedFolder)) {
                            // Nothing
                          } else {
                            setState(() {
                              editFailed = true;
                            });
                          }

                          widget.notifier.notifyListeners();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          setState(() {});
                          widget.notifier.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ),
              )
            ]),
            decoration: BoxDecoration(
                color: hovering ? MyTheme.grey60 : MyTheme.grey50),
          ),
        ));
  }
}

class PresetEntryWidget extends StatefulWidget {
  PresetInfo info;
  String selected;
  final void Function() onTap;
  final bool locked;
  ValueNotifier<int> notifier;

  Host host;

  PresetEntryWidget(
    this.host,
      {required this.info,
      required this.selected,
      required this.onTap,
      required this.locked,
      required this.notifier})
      : super(key: UniqueKey());

  @override
  State<PresetEntryWidget> createState() => _PresetEntryWidgetState();
}

class _PresetEntryWidgetState extends State<PresetEntryWidget> {
  String editingText = "";

  bool hovering = false;
  bool editing = false;
  bool editFailed = false;

  var lastTapTime = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    var tile = Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      height: 44,
      child: Stack(children: [
        Align(
          alignment: Alignment.centerLeft,

          /* Static name text */
          child: !editing
              ? Text(
                  widget.info.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300),
                )
              :

              /* Editable name text */
              Container(
                  width: 210,
                  height: 26,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MyTheme.grey50,
                    border: Border.all(
                      color: editFailed ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: EditableText(
                      controller: TextEditingController.fromValue(
                          TextEditingValue(text: editingText)),
                      onChanged: (text) {
                        editingText = text;
                      },
                      onSubmitted: (text) {
                        if (renamePreset(widget.info, text)) {
                          setState(() {
                            editing = false;
                            editFailed = false;
                          });
                        } else {
                          setState(() {
                            editFailed = true;
                          });
                        }

                        widget.notifier.notifyListeners();
                      },
                      focusNode: FocusNode(),
                      cursorColor: Colors.blue,
                      backgroundCursorColor: Colors.blue,
                      maxLines: 1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: Colors.white,
                          decoration: TextDecoration.none)),
                ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: !editing
              ? Visibility(
                  visible: hovering && !widget.locked,
                  child: Container(
                    width: 160,
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          setState(() {
                            editing = true;
                            editingText = widget.info.name;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          duplicatePreset(widget.info);
                          widget.notifier.notifyListeners();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          removePreset(widget.info);
                          widget.notifier.notifyListeners();
                        },
                      )
                    ]),
                  ))
              : Container(
                  width: 80,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.save),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          if (renamePreset(widget.info, editingText)) {
                            setState(() {
                              editing = false;
                              editFailed = false;
                            });
                          } else {
                            setState(() {
                              editFailed = true;
                            });
                          }

                          widget.notifier.notifyListeners();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: Colors.white,
                        iconSize: 16,
                        onPressed: () {
                          setState(() {
                            editing = false;
                            editFailed = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
        ),
        widget.locked
            ? Container()
            : Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.drag_handle),
                  color: Colors.white,
                  iconSize: 16,
                  onPressed: () {
                    setState(() {
                      editing = false;
                      editFailed = false;
                    });
                  },
                ),
              ),
      ]),
      decoration: BoxDecoration(
        color: widget.selected == widget.info.name
            ? MyTheme.grey70
            : (hovering ? MyTheme.grey60 : MyTheme.grey50),
      ),
    );

    var dragTile = Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: 320 + 50 - 20 - 40,
      height: 44,
      child: Stack(children: [
        Align(
            alignment: Alignment.centerLeft,

            /* Static name text */
            child: Text(
              widget.info.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.normal,
                  decoration: TextDecoration.none),
            )),
      ]),
      decoration: BoxDecoration(
        color: widget.selected == widget.info.name
            ? MyTheme.grey70
            : (hovering ? MyTheme.grey60 : MyTheme.grey50),
      ),
    );

    return MouseRegion(
        opaque: false,
        onEnter: (event) {
          setState(() {
            hovering = true;
          });
        },
        onExit: (event) {
          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
          onTapDown: (event) {
            /*var time = DateTime.now().millisecondsSinceEpoch;

            if (time - lastTapTime > 500) {
              lastTapTime = time;
              //onTap(); // Single tap
            } else {
              loadPreset(info.file);
            }*/
          },
          onDoubleTap: () {
            widget.host.loadPreset(widget.info.file);
            widget.notifier.notifyListeners();
          },
          child: widget.locked
              ? tile
              : Draggable(
                  child: tile,
                  feedback: dragTile,
                  childWhenDragging: Container(),
                  data: widget.info.name,
                ),
        ));
  }
}

class PresetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: MyTheme.grey40,
      thickness: 1.0,
      indent: 0.0,
      endIndent: 0.0,
      height: 1.0,
    );
  }
}

class PresetAddWidget extends StatefulWidget {
  final Function() onClick;

  PresetAddWidget({required this.onClick});

  @override
  State<PresetAddWidget> createState() =>
      _PresetAddWidgetState(onClick: onClick);
}

class _PresetAddWidgetState extends State<PresetAddWidget> {
  bool hovering = false;
  final Function() onClick;

  _PresetAddWidgetState({required this.onClick});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (event) {
        setState(() {
          hovering = false;
        });
      },
      child: GestureDetector(
        onTap: onClick,
        child: Container(
          height: 35,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              "+",
              style: TextStyle(
                  color: hovering ? Colors.white : Colors.white60,
                  fontSize: 16,
                  fontWeight: FontWeight.w300),
            ),
          ),
          decoration: BoxDecoration(
            color: hovering
                ? MyTheme.grey50
                : const Color.fromRGBO(43, 43, 43, 1.0),
          ),
        ),
      ),
    );
  }
}

/*class PresetGroup extends StatefulWidget {
  PresetGroup(
      {required this.host,
      required this.name,
      required this.presets,
      required this.index})
      : super(key: UniqueKey());
  String name;
  List<PresetEntry> presets;
  int index;
  Host host;

  @override
  _PresetGroup createState() => _PresetGroup();
}

class _PresetGroup extends State<PresetGroup> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
        child: Column(children: [
          Container(
              height: 35,
              decoration: BoxDecoration(
                  color: hovering
                      ? const Color.fromRGBO(70, 70, 70, 1.0)
                      : const Color.fromRGBO(60, 60, 60, 1.0),
                  borderRadius: const BorderRadius.all(Radius.circular(5))),
              child: MouseRegion(
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
                        setState(() {
                          expanded = !expanded;
                        });
                      },
                      child: Row(children: [
                        const SizedBox(
                            width: 40,
                            child: Icon(
                              Icons.folder,
                              color: Colors.blueAccent,
                              size: 18,
                            )),
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Text(
                                  widget.name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ))),
                        SizedBox(
                            width: 40,
                            child: ReorderableDragStartListener(
                                index: widget.index,
                                child: const Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                )))
                      ])))),
          AnimatedSize(
              curve: Curves.fastLinearToSlowEaseIn,
              duration: const Duration(milliseconds: 500),
              child: Container(
                  height: expanded ? null : 0,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(60, 60, 60, 1.0),
                      borderRadius: expanded
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(5))
                          : const BorderRadius.all(Radius.circular(5))),
                  child: SizedBox(
                    height: widget.presets.length * 30 + 10,
                    child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          var element = widget.presets.removeAt(oldIndex);
                          if (newIndex >= widget.presets.length) {
                            widget.presets.add(element);
                          } else {
                            widget.presets.insert(newIndex, element);
                          }

                          for (int i = 0; i < widget.presets.length; i++) {
                            widget.presets[i].listIndex = i;
                          }
                        },
                        children: widget.presets),
                  )))
        ]));
  }
}

class PresetEntry extends StatefulWidget {
  PresetEntry(
      {required this.host,
      required this.id,
      required this.name,
      required this.notifier,
      required this.selectedVar,
      required this.listIndex})
      : super(key: UniqueKey());

  Host host;
  int id;
  ValueNotifier<String> name;
  ValueNotifier<dynamic> notifier;
  ValueNotifier<PresetEntry?> selectedVar;
  int listIndex;

  @override
  _PresetEntry createState() => _PresetEntry();
}

class _PresetEntry extends State<PresetEntry> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    String typeName = "Unknown";

    if (widget.notifier.value.runtimeType == double) {
      typeName = "double";
    } else if (widget.notifier.value.runtimeType == bool) {
      typeName = "bool";
    }

    var w = ValueListenableBuilder<PresetEntry?>(
        valueListenable: widget.selectedVar,
        builder: (context, selectedVar, child) {
          return Container(
            height: 35,
            width: 300,
            decoration: BoxDecoration(
                color: selectedVar == widget
                    ? (hovering
                        ? const Color.fromRGBO(90, 90, 90, 1.0)
                        : const Color.fromRGBO(80, 80, 80, 1.0))
                    : (hovering
                        ? const Color.fromRGBO(70, 70, 70, 1.0)
                        : const Color.fromRGBO(60, 60, 60, 1.0)),
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                  ),
                ),
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: ValueListenableBuilder<String>(
                            valueListenable: widget.name,
                            builder: ((context, name, child) {
                              return Text(name,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white));
                            })))),
                Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ValueListenableBuilder(
                        valueListenable: widget.notifier,
                        builder: (context, value, child) {
                          return Text(formatValue(value),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w300));
                        })),
                ReorderableDragStartListener(
                    index: widget.listIndex,
                    child: const SizedBox(
                      width: 40,
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                      ),
                    ))
              ],
            ),
          );
        });

    return Padding(
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
        child: MouseRegion(
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
                  if (widget == widget.selectedVar.value) {
                    widget.selectedVar.value = null;
                  } else {
                    widget.selectedVar.value = widget;
                  }
                },
                child: Draggable<PresetEntry>(
                    data: widget,
                    feedback: Container(
                        width: 180,
                        height: 30,
                        decoration: const BoxDecoration(
                            color: Color.fromRGBO(80, 80, 80, 0.3),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.5),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5))),
                                  )),
                              Expanded(
                                  child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 10, 0),
                                      child: ValueListenableBuilder<String>(
                                          valueListenable: widget.name,
                                          builder: ((context, name, child) {
                                            return Text(name,
                                                style: const TextStyle(
                                                    decoration:
                                                        TextDecoration.none,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 13,
                                                    color: Color.fromRGBO(
                                                        255, 255, 255, 0.5)));
                                          })))),
                            ])),
                    childWhenDragging: const SizedBox(width: 0, height: 0),
                    child: w))));
  }
}

String formatValue(dynamic value) {
  var text = value.toString();

  if (value is double) {
    text = value.toStringAsFixed(2);
  }

  return text;
}*/
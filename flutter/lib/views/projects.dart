import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'info.dart';

import '../globals.dart';
import '../main.dart';

class ProjectsBrowser extends StatefulWidget {
  ProjectsBrowser({
    required this.app,
    required this.onLoadProject,
  });

  App app;
  void Function(ProjectInfo) onLoadProject;

  @override
  State<ProjectsBrowser> createState() => _ProjectsBrowser();
}

class _ProjectsBrowser extends State<ProjectsBrowser> {
  String searchText = "";
  bool editing = false;

  void newProject() async {
    print("Calling new project");
    var newName = "New Project";
    var newPath = Globals.assets.projects.directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = "New Project " + i.toString();
      newPath = Globals.assets.projects.directory.path + "/" + newName;
      i++;
    }

    var newInfo = ProjectInfo(
      directory: Directory(newPath),
      name: ValueNotifier(newName),
      description: ValueNotifier("A new project description"),
      image: ValueNotifier(null),
      date: ValueNotifier(DateTime.now()),
      tags: [],
    );

    await newInfo.save();

    Globals.assets.projects.list().value.add(newInfo);
    Globals.assets.projects.list().notifyListeners();
  }

  void duplicateProject(ProjectInfo info) async {
    var newName = info.name.value + " (copy)";
    var newPath = Globals.assets.projects.directory.path + "/" + newName;

    int i = 2;
    while (await Directory(newPath).exists()) {
      newName = info.name.value + " (copy " + i.toString() + ")";
      newPath = Globals.assets.projects.directory.path + "/" + newName;
      i++;
    }

    await Process.run("cp", ["-r", info.directory.path, newPath]);
    var newInfo = await ProjectInfo.load(newPath);

    if (newInfo != null) {
      newInfo.name.value = newName;
      newInfo.date.value = DateTime.now();
      await newInfo.save();

      Globals.assets.projects.list().value.add(newInfo);
      Globals.assets.projects.list().notifyListeners();
    }
  }

  void removeProject(ProjectInfo info) async {
    print("Removing project");
    await info.directory.delete(recursive: true);
    Globals.assets.projects.list().value.remove(info);
    Globals.assets.projects.list().notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(20, 20, 20, 1.0),
        ),
        constraints: const BoxConstraints(maxWidth: 300 * 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: BigTags(
                onEditPressed: () {
                  setState(() {
                    editing = !editing;
                  });
                },
                onNewPressed: () {
                  newProject();
                },
                onSearch: (s) {
                  setState(() {
                    searchText = s;
                  });
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<ProjectInfo>>(
                valueListenable: Globals.assets.projects.list(),
                builder: (context, projects, child) {
                  List<ProjectInfo> filteredProjects = [];
                  if (searchText == "") {
                    filteredProjects = projects;
                  } else {
                    for (var project in projects) {
                      if (project.name.value
                              .toLowerCase()
                              .contains(searchText.toLowerCase()) ||
                          project.description.value
                              .toLowerCase()
                              .contains(searchText.toLowerCase())) {
                        filteredProjects.add(project);
                      }
                    }
                  }

                  if (filteredProjects.isEmpty) {
                    return Container();
                  }

                  filteredProjects.sort((a, b) {
                    return b.date.value.compareTo(a.date.value);
                  });

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      mainAxisExtent: 300,
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return ProjectPreview(
                        index: index,
                        editing: editing,
                        project: filteredProjects[index],
                        onOpen: (info) {
                          widget.onLoadProject(info);
                        },
                        onDuplicate: (info) {
                          duplicateProject(info);
                        },
                        onDelete: (info) {
                          removeProject(info);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewInstrumentButton extends StatelessWidget {
  NewInstrumentButton({required this.onPressed});

  void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(50, 100, 50, 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.add,
          size: 20,
        ),
        color: Colors.green,
        onPressed: onPressed,
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  SearchBar({required this.onFilter});

  void Function(String) onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 35,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(30, 30, 30, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: TextField(
        textAlignVertical: TextAlignVertical.center,
        maxLines: 1,
        style: const TextStyle(
          color: Color.fromRGBO(220, 220, 220, 1.0),
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(8),
          prefixIconColor: Colors.grey,
          prefixIcon: Icon(
            Icons.search,
          ),
        ),
        onChanged: (text) {
          onFilter(text);
        },
      ),
    );
  }
}

class TagRow {
  const TagRow({required this.name, required this.color, required this.tags});

  final String name;
  final Color color;
  final List<String> tags;
}

class BigTags extends StatelessWidget {
  BigTags({
    required this.onEditPressed,
    required this.onNewPressed,
    required this.onSearch,
  });

  void Function() onEditPressed;
  void Function() onNewPressed;
  void Function(String) onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SearchBar(onFilter: onSearch),
        Expanded(
          child: Container(),
        ),
        const SizedBox(width: 10),
        BigTagDropdown(
          text: "Instrument",
          color: Colors.white,
          iconData: Icons.piano,
          rows: const [
            TagRow(
              name: "Sources",
              color: Colors.red,
              tags: [
                "Sampled",
                "Multi-sampled",
                "Physical Modelling",
              ],
            ),
            TagRow(
              name: "Keyboards",
              color: Colors.red,
              tags: [
                "Acoustic Piano",
                "Electric Piano",
                "Harpsichord",
                "Clavichord",
              ],
            ),
            TagRow(
              name: "Guitars",
              color: Colors.red,
              tags: [
                "Acoustic Guitar",
                "Electric Guitar",
                "Mandolin",
                "Bass Guitar",
              ],
            ),
            TagRow(
              name: "Synthesizer",
              color: Colors.red,
              tags: [
                "Synth Lead",
                "Synth Pluck",
                "Synth Pad",
                "Synth Bass",
                "Digital",
                "Virtual Analog",
              ],
            ),
            TagRow(
              name: "Orchestral",
              color: Colors.red,
              tags: [
                "Strings",
                "Woodwinds",
                "Brass",
                "Percussion",
              ],
            ),
            TagRow(
              name: "Orchestral",
              color: Colors.red,
              tags: ["Strings", "Woodwinds", "Brass", "Percussion"],
            ),
            TagRow(
              name: "Orchestral",
              color: Colors.red,
              tags: ["Strings", "Woodwinds", "Brass", "Percussion"],
            ),
            TagRow(
              name: "Orchestral",
              color: Colors.red,
              tags: ["Strings", "Woodwinds", "Brass", "Percussion"],
            ),
          ],
        ),
        const SizedBox(width: 10),
        BigTagDropdown(
          text: "Effect",
          color: Colors.white,
          iconData: Icons.waves,
          rows: const [
            TagRow(
              name: "Row",
              color: Colors.red,
              tags: ["Item 1", "Item 2"],
            ),
          ],
        ),
        const SizedBox(width: 10),
        BigTagDropdown(
          text: "Sequencer",
          color: Colors.white,
          iconData: Icons.music_note,
          rows: const [
            TagRow(
              name: "Row",
              color: Colors.red,
              tags: ["Item 1", "Item 2"],
            ),
          ],
        ),
        const SizedBox(width: 10),
        BigTagDropdown(
          text: "Song",
          color: Colors.white,
          iconData: Icons.equalizer,
          rows: const [
            TagRow(
              name: "Row",
              color: Colors.red,
              tags: ["Item 1", "Item 2"],
            ),
          ],
        ),
        const SizedBox(width: 10),
        BigTagDropdown(
          text: "Utility",
          color: Colors.white,
          iconData: Icons.developer_board,
          rows: const [
            TagRow(
              name: "Row",
              color: Colors.red,
              tags: ["Item 1", "Item 2"],
            ),
          ],
        ),
        const SizedBox(width: 10),
        NewInstrumentButton(
          onPressed: () {
            onNewPressed();
          },
        ),
      ],
    );
  }
}

class BigTagDropdown extends StatefulWidget {
  BigTagDropdown({
    required this.text,
    required this.color,
    required this.iconData,
    required this.rows,
  });

  String text;
  Color color;
  IconData iconData;
  List<TagRow> rows;

  @override
  State<BigTagDropdown> createState() => _BigTagDropdown();
}

class _BigTagDropdown extends State<BigTagDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  bool hovering = false;
  bool active = false;

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  ScrollController _scrollController = ScrollController();

  void toggleDropdown({bool? open}) async {
    if (_isOpen || open == false) {
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else if (!_isOpen || open == true) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      maintainState: false,
      opaque: false,
      builder: (entryContext) {
        return FocusScope(
          node: _focusScopeNode,
          child: GestureDetector(
            onTap: () {
              toggleDropdown(open: false);
            },
            onSecondaryTap: () {
              toggleDropdown(open: false);
            },
            onPanStart: (e) {
              toggleDropdown(open: false);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Positioned(
                    left: offset.dx - 50,
                    top: offset.dy + size.height + 5,
                    child: CompositedTransformFollower(
                      offset: Offset(0, size.height),
                      link: _layerLink,
                      showWhenUnlinked: false,
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.zero,
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                          child: GestureDetector(
                            onTap: () {},
                            onSecondaryTap: () {},
                            onPanStart: (e) {},
                            child: Container(
                              width: 500,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(40, 40, 40, 1.0),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color.fromRGBO(60, 60, 60, 1.0),
                                  width: 1.0,
                                ),
                              ),
                              child: Scrollbar(
                                thumbVisibility: true,
                                controller: _scrollController,
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: widget.rows.map(
                                        (e) {
                                          return TagDropdownRow(
                                            name: e.name,
                                            tags: e.tags,
                                            onTap: (n) {
                                              // widget.onAction(n);
                                              toggleDropdown(open: false);
                                            },
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
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
            toggleDropdown();
          },
          child: Container(
            height: 35,
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            decoration: BoxDecoration(
              color: (hovering || _isOpen)
                  ? const Color.fromRGBO(40, 40, 40, 1.0)
                  : const Color.fromRGBO(30, 30, 30, 1.0),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      widget.iconData,
                      size: 16,
                      color: active ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 30,
                  height: 35,
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: active ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectPreview extends StatefulWidget {
  ProjectPreview({
    required this.index,
    required this.editing,
    required this.project,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  int index;
  bool editing;
  ProjectInfo project;
  void Function(ProjectInfo) onOpen;
  void Function(ProjectInfo) onDuplicate;
  void Function(ProjectInfo) onDelete;

  @override
  State<ProjectPreview> createState() => _ProjectPreview();
}

class _ProjectPreview extends State<ProjectPreview>
    with TickerProviderStateMixin {
  bool mouseOver = false;
  bool playing = false;
  late AnimationController controller;
  int updateCount = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  void replaceImage() async {
    var result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select a project image",
      type: FileType.image,
      allowMultiple: false,
      allowedExtensions: ["jpg", "png", "jpeg"],
    );

    if (result != null) {
      var file = File(result.files.first.path!);
      String dest = widget.project.directory.path +
          "/background." +
          file.path.split(".").last;

      await widget.project.image.value?.delete();
      await file.copy(dest);
      updateCount += 1;
      widget.project.image.value = File(dest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (details) {
                setState(() {
                  mouseOver = true;
                });
              },
              onExit: (details) {
                setState(() {
                  mouseOver = false;
                });
              },
              child: GestureDetector(
                onTap: () => widget.onOpen(widget.project),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                      child: ValueListenableBuilder<File?>(
                        valueListenable: widget.project.image,
                        builder: (context, file, child) {
                          if (file != null) {
                            return Image.file(
                              file,
                              key: ValueKey(updateCount),
                              width: 290,
                              fit: BoxFit.cover,
                            );
                          } else {
                            return Container(
                              color: const Color.fromRGBO(40, 40, 40, 1.0),
                            );
                          }
                        },
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: mouseOver ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ProjectPreviewDescription(
            project: widget.project,
            onAction: (action) {
              if (action == "Open Project") {
                widget.onOpen(widget.project);
              } else if (action == "Replace Image") {
                replaceImage();
              } else if (action == "Duplicate Project") {
                widget.onDuplicate(widget.project);
              } else if (action == "Delete Project") {
                widget.onDelete(widget.project);
              }
            },
          )
        ],
      ),
    );
  }
}

class ProjectPreviewDescription extends StatefulWidget {
  ProjectPreviewDescription({
    required this.project,
    required this.onAction,
  });

  ProjectInfo project;
  void Function(String) onAction;

  @override
  State<ProjectPreviewDescription> createState() =>
      _ProjectPreviewDescription();
}

class _ProjectPreviewDescription extends State<ProjectPreviewDescription> {
  bool barHovering = false;
  bool editing = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  bool nameSubmitHovering = false;

  void startEditingProject() {
    setState(() {
      nameController.text = widget.project.name.value;
      descController.text = widget.project.description.value;
      editing = true;
    });
  }

  void cancelEditingProject() {
    setState(() {
      editing = false;
    });
  }

  void doneEditingProject() {
    widget.project.name.value = nameController.text;
    widget.project.description.value = descController.text;
    widget.project.save();
    setState(() {
      editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (e) {
              setState(() {
                barHovering = true;
              });
            },
            onExit: (e) {
              setState(() {
                barHovering = false;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (editing) {
                        return Container(
                          height: 24,
                          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: nameController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(220, 220, 220, 1.0),
                                  ),
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Color.fromRGBO(40, 40, 40, 1.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding:
                                        EdgeInsets.fromLTRB(5, 0, 0, 0),
                                  ),
                                  onSubmitted: (value) {
                                    doneEditingProject();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                                child: CircleButton(
                                  icon: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  onTap: () {
                                    doneEditingProject();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                                child: CircleButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  onTap: () {
                                    cancelEditingProject();
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ValueListenableBuilder<String>(
                          valueListenable: widget.project.name,
                          builder: (context, name, child) {
                            return Text(
                              widget.project.name.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(220, 220, 220, 1.0),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                MoreDropdown(
                  items: const [
                    "Open Project",
                    "Edit Project",
                    "Replace Image",
                    "Duplicate Project",
                    "Delete Project"
                  ],
                  onAction: (s) {
                    if (s == "Edit Project") {
                      startEditingProject();
                    } else {
                      widget.onAction(s);
                    }
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Builder(
              builder: (context) {
                if (editing) {
                  return TextField(
                    maxLines: 2,
                    controller: descController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: Color.fromRGBO(40, 40, 40, 1.0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: Colors.grey,
                        ),
                      ),
                      contentPadding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    ),
                    onSubmitted: (value) {
                      doneEditingProject();
                    },
                  );
                } else {
                  return ValueListenableBuilder<String>(
                    valueListenable: widget.project.description,
                    builder: (context, description, child) {
                      return Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      );
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}

class CircleButton extends StatefulWidget {
  CircleButton({
    required this.icon,
    required this.onTap,
    this.color = const Color.fromRGBO(40, 40, 40, 1.0),
    this.hoverColor = const Color.fromRGBO(30, 30, 30, 1.0),
  });

  final Icon icon;
  final Color color;
  final Color hoverColor;
  final void Function() onTap;

  @override
  State<CircleButton> createState() => _CircleButton();
}

class _CircleButton extends State<CircleButton> {
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
        onTap: widget.onTap,
        child: AnimatedContainer(
          width: 20,
          height: 20,
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: hovering ? widget.hoverColor : widget.color,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: widget.icon,
        ),
      ),
    );
  }
}

class MoreDropdown extends StatefulWidget {
  MoreDropdown({
    required this.items,
    required this.onAction,
    this.color = const Color.fromRGBO(40, 40, 40, 1.0),
    this.hoverColor = const Color.fromRGBO(30, 30, 30, 1.0),
  });

  final List<String> items;
  final Color color;
  final Color hoverColor;
  final void Function(String) onAction;

  @override
  State<MoreDropdown> createState() => _MoreDropdown();
}

class _MoreDropdown extends State<MoreDropdown> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  bool hovering = false;

  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  void toggleDropdown({bool? open}) async {
    if (_isOpen || open == false) {
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else if (!_isOpen || open == true) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      maintainState: false,
      opaque: false,
      builder: (entryContext) {
        return FocusScope(
          node: _focusScopeNode,
          child: GestureDetector(
            onTap: () {
              toggleDropdown(open: false);
            },
            onSecondaryTap: () {
              toggleDropdown(open: false);
            },
            onPanStart: (e) {
              toggleDropdown(open: false);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Positioned(
                    left: offset.dx - 50,
                    top: offset.dy + size.height + 5,
                    child: CompositedTransformFollower(
                      offset: Offset(0, size.height),
                      link: _layerLink,
                      showWhenUnlinked: false,
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.zero,
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(30, 30, 30, 1.0),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color.fromRGBO(50, 50, 50, 1.0),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.items.map(
                                (text) {
                                  return MoreElement(
                                    name: text,
                                    onTap: (n) {
                                      widget.onAction(n);
                                      toggleDropdown(open: false);
                                    },
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CircleButton(
        icon: const Icon(
          Icons.more_horiz_outlined,
          color: Colors.grey,
          size: 14,
        ),
        onTap: () {
          toggleDropdown();
        },
        color: widget.color,
        hoverColor: widget.hoverColor,
      ),
    );
  }
}

class MoreElement extends StatefulWidget {
  MoreElement({required this.name, required this.onTap});

  String name;
  void Function(String) onTap;

  @override
  State<MoreElement> createState() => _MoreElement();
}

class _MoreElement extends State<MoreElement> {
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
        onTap: () {
          widget.onTap(widget.name);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          color: hovering
              ? const Color.fromRGBO(40, 40, 40, 1.0)
              : const Color.fromRGBO(30, 30, 30, 1.0),
          child: Text(
            widget.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class TagDropdownRow extends StatefulWidget {
  TagDropdownRow({required this.name, required this.tags, required this.onTap});

  String name;
  List<String> tags;
  void Function(String) onTap;

  @override
  State<TagDropdownRow> createState() => _TagDropdownRow();
}

class _TagDropdownRow extends State<TagDropdownRow> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
              SizedBox(
                width: 100,
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ),
            ] +
            widget.tags
                .map(
                  (e) => Tag(
                    name: e,
                    color: Colors.red,
                    onTap: () {
                      print("Tapped " + e);
                    },
                  ),
                )
                .toList(),
      ),
    );
  }
}

class Tag extends StatefulWidget {
  Tag({required this.name, required this.color, required this.onTap});

  final String name;
  final Color color;
  final void Function() onTap;

  @override
  State<Tag> createState() => _Tag();
}

class _Tag extends State<Tag> {
  bool hovering = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
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
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: hovering
                  ? const Color.fromRGBO(30, 30, 30, 1.0)
                  : const Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Text(
              widget.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

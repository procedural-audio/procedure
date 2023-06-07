import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metasampler/common.dart';
import 'package:metasampler/patch.dart';

import 'dart:math';

import 'info.dart';
import '../main.dart';

/*

Type: Instrument, effect, sequencer, song, utility
Instrument: Synth, bass, soundscape, piano, voice, guitar, sound effects, mallets, keyboard...
Instrument Type: 

*/

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
                  setState(() {
                    print("New instrument");
                  });
                },
                onSearch: (s) {
                  setState(() {
                    searchText = s;
                  });
                },
              ),
            ),
            /*Selector(
              elements: const [
                "Instrument",
                "Effect",
                "Sequencer",
                "Song",
                "Utility"
              ],
              onSelect: (e) {
                print("Selected " + e);
              },
            ),*/
            /*Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: BrowserSearchBar(
                onFilter: (s) {
                  setState(() {
                    searchText = s;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),*/
            Expanded(
              child: ValueListenableBuilder<List<ProjectInfo>>(
                valueListenable: widget.app.assets.projects.list(),
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

                  print("Sorting projects");
                  filteredProjects.sort((a, b) {
                    return b.date.value.compareTo(a.date.value);
                  });

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
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
                      return BrowserViewElement(
                        index: index,
                        editing: editing,
                        project: filteredProjects[index],
                        onOpen: (info) {
                          widget.onLoadProject(info);
                        },
                        onDuplicate: (info) {},
                        onDelete: (info) {},
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

class InstrumentEditor extends StatefulWidget {
  InstrumentEditor({
    required this.app,
    required this.onSave,
    required this.onCancel,
  });

  App app;
  void Function() onSave;
  void Function() onCancel;

  @override
  State<InstrumentEditor> createState() => _InstrumentEditor();
}

class _InstrumentEditor extends State<InstrumentEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
    );
  }
}

class NewInstrumentButton extends StatelessWidget {
  NewInstrumentButton({required this.onPressed});

  void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(50, 100, 50, 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: const Icon(Icons.add),
        color: Colors.green,
        onPressed: onPressed,
      ),
    );
  }
}

class EditButton extends StatelessWidget {
  EditButton({required this.onPressed});

  void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(30, 30, 30, 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: const Icon(Icons.edit),
        iconSize: 18,
        color: Colors.grey,
        onPressed: onPressed,
      ),
    );
  }
}

/*class Selector extends StatelessWidget {
  Selector({required this.elements, required this.onSelect});

  List<String> elements;
  void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(10, 10, 10, 1.0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromRGBO(40, 40, 40, 1.0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: elements
            .map((e) => Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}*/

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
        /*Dropdown( // Sort by recent, name, etc.
          value: "Item 1",
          items: const ["Item 1", "Item 2", "Item 3"],
          onChanged: (s) {},
          color: Colors.blue,
        ),*/
        Expanded(
          child: Container(),
        ),
        BigTag(
          active: true,
          text: "Instrument",
          color: Colors.white,
          iconData: Icons.piano,
        ),
        const SizedBox(width: 10),
        BigTag(
          active: false,
          text: "Effect",
          color: Colors.white,
          iconData: Icons.waves,
        ),
        const SizedBox(width: 10),
        BigTag(
          active: false,
          text: "Sequencer",
          color: Colors.white,
          iconData: Icons.music_note,
        ),
        const SizedBox(width: 10),
        BigTag(
          active: false,
          text: "Song",
          color: Colors.white,
          iconData: Icons.equalizer,
        ),
        const SizedBox(width: 10),
        BigTag(
          active: false,
          text: "Utility",
          color: Colors.white,
          iconData: Icons.developer_board,
        ),
        const SizedBox(width: 10),
        EditButton(
          onPressed: () {
            print("Edit");
          },
        ),
        const SizedBox(width: 10),
        NewInstrumentButton(
          onPressed: () {
            print("New instrument");
          },
        ),
      ],
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
      height: 30,
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

class BigTag extends StatelessWidget {
  BigTag({
    required this.active,
    required this.text,
    required this.color,
    required this.iconData,
  });

  String text;
  Color color;
  IconData iconData;
  bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(10, 10, 15, 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(40, 40, 40, 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          color: active ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 18,
            color: active ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class BrowserSearchBar extends StatelessWidget {
  BrowserSearchBar({required this.onFilter});

  void Function(String) onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TagDropdown(
                  value: "Type",
                  tags: const [
                    "Synthesizer",
                    "Sampler",
                    "Effect",
                    "Sequencer",
                    "Song",
                    "Application",
                  ],
                  onSelect: (s) {},
                ),
                TagDropdown(
                  value: "Attributes",
                  tags: const [
                    "Analog",
                    "Generative",
                  ],
                  onSelect: (s) {},
                ),
                TagDropdown(
                  value: "Other",
                  tags: const [
                    "Analog",
                    "Generative",
                  ],
                  onSelect: (s) {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BrowserViewElement extends StatefulWidget {
  BrowserViewElement({
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
  State<BrowserViewElement> createState() => _BrowserViewElement();
}

class _BrowserViewElement extends State<BrowserViewElement>
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
          BrowserViewElementDescription(
            project: widget.project,
            onAction: (action) {
              if (action == "Open Project") {
                widget.onOpen(widget.project);
              } else if (action == "Rename Project") {
              } else if (action == "Edit Description") {
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

class BrowserViewElementDescription extends StatefulWidget {
  BrowserViewElementDescription({
    required this.project,
    required this.onAction,
  });

  ProjectInfo project;
  void Function(String) onAction;

  @override
  State<BrowserViewElementDescription> createState() =>
      _BrowserViewElementDescription();
}

class _BrowserViewElementDescription
    extends State<BrowserViewElementDescription> {
  bool barHovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(4),
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
                  child: Text(
                    widget.project.name.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(220, 220, 220, 1.0),
                    ),
                  ),
                ),
                /*AnimatedOpacity(
                  opacity: barHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: GestureDetector(
                    onTap: () {
                      print("more");
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(30, 30, 30, 1.0),
                          width: 2,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        color: const Color.fromRGBO(30, 30, 30, 1.0),
                      ),
                      child: const Icon(
                        Icons.more_horiz_outlined,
                        color: Colors.grey,
                        size: 14,
                      ),
                    ),
                  ),
                ),*/
                MoreDropdown(
                  items: const [
                    "Open Project",
                    "Rename Project",
                    "Edit Description",
                    "Replace Image",
                    "Duplicate Project",
                    "Delete Project"
                  ],
                  onAction: widget.onAction,
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ValueListenableBuilder<String>(
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
            ),
          ),
        ],
      ),
    );
  }
}

class MoreDropdown extends StatefulWidget {
  MoreDropdown({
    required this.items,
    required this.onAction,
  });

  List<String> items;
  void Function(String) onAction;

  @override
  State<MoreDropdown> createState() => _MoreDropdown();
}

class _MoreDropdown extends State<MoreDropdown> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          toggleDropdown();
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(30, 30, 30, 1.0),
              width: 2,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
            color: const Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Icon(
            Icons.more_horiz_outlined,
            color: Colors.grey,
            size: 14,
          ),
        ),
      ),
    );
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

/*class BrowserViewElementOverlay extends StatelessWidget {
  BrowserViewElementOverlay({
    required this.icon,
    required this.alignment,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final Widget icon;
  final Alignment alignment;
  final EdgeInsets padding;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 30, 30, 1.0),
              borderRadius: const BorderRadius.all(
                Radius.circular(20),
              ),
              border: Border.all(
                color: const Color.fromRGBO(40, 40, 40, 1.0),
                width: 1.0,
              ),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}*/

class TagDropdown extends StatefulWidget {
  TagDropdown({
    required this.value,
    required this.tags,
    required this.onSelect,
    this.width,
    this.height = 24,
    this.decoration = const BoxDecoration(
      color: Color.fromRGBO(20, 20, 20, 1.0),
      borderRadius: BorderRadius.all(
        Radius.circular(3),
      ),
    ),
  });

  String? value;
  List<String> tags;
  void Function(String?) onSelect;
  double? width;
  double? height;
  BoxDecoration decoration;

  @override
  State<TagDropdown> createState() => _TagDropdown();
}

class _TagDropdown extends State<TagDropdown> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  TextEditingController searchController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 0));
  }

  void toggleDropdown({bool? open}) async {
    if (_isOpen || open == false) {
      await _animationController?.reverse();
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else if (!_isOpen || open == true) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () {
            toggleDropdown();
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
                color: _isOpen
                    ? const Color.fromRGBO(100, 100, 100, 1.0)
                    : const Color.fromRGBO(50, 50, 50, 1.0),
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            child: Text(
              widget.value ?? "",
              style: TextStyle(
                fontSize: 12,
                color: _isOpen
                    ? const Color.fromRGBO(20, 20, 20, 1.0)
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
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
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color.fromRGBO(30, 30, 30, 1.0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color.fromRGBO(40, 40, 40, 1.0),
                                  width: 1.0)),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.tags.map((name) {
                              return TagDropdownElement(
                                name: name,
                                onSelect: widget.onSelect,
                              );
                            }).toList(),
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
}

class TagDropdownElement extends StatefulWidget {
  const TagDropdownElement({required this.name, required this.onSelect});

  final String name;
  final void Function(String) onSelect;

  @override
  State<TagDropdownElement> createState() => _TagDropdownElement();
}

class _TagDropdownElement extends State<TagDropdownElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: MouseRegion(
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
            widget.onSelect(widget.name);
          },
          child: Container(
            height: 22,
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
              border: Border.all(
                width: 1.0,
                color: !hovering
                    ? const Color.fromRGBO(60, 60, 60, 1.0)
                    : const Color.fromRGBO(100, 100, 100, 1.0),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

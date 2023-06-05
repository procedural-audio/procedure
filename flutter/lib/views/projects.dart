import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:math';

import 'info.dart';

import '../projects.dart';
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
              child: BigTags(),
            ),
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
                          project.description
                              .toLowerCase()
                              .contains(searchText.toLowerCase())) {
                        filteredProjects.add(project);
                      }
                    }
                  }

                  if (filteredProjects.isEmpty) {
                    return Container();
                  }

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
                        project: filteredProjects[index],
                        onTap: (info) {
                          widget.onLoadProject(info);
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

class BigTags extends StatelessWidget {
  BigTags();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SearchBar(onFilter: (s) {}),
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
    required this.project,
    required this.onTap,
  });

  int index;
  ProjectInfo project;
  void Function(ProjectInfo) onTap;

  @override
  State<BrowserViewElement> createState() => _BrowserViewElement();
}

class _BrowserViewElement extends State<BrowserViewElement>
    with TickerProviderStateMixin {
  bool mouseOver = false;
  bool playing = false;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
        onTap: () => widget.onTap(widget.project),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                      child: Image.file(
                        File(widget.project.background),
                        width: 290,
                        fit: BoxFit.cover,
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
              Container(
                height: 80,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      widget.project.name.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(220, 220, 220, 1.0),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(60, 60, 60, 1.0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "32",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(60, 60, 60, 1.0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "64",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        widget.project.description,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

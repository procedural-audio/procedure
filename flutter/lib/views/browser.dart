/*class BrowserView extends StatefulWidget {
  BrowserView(this.app);

  App app;

  @override
  State<BrowserView> createState() => _BrowserView();
}

class _BrowserView extends State<BrowserView> {
  bool expanded = false;
  String searchText = "";
  bool infoVisible = false;
  bool showInfo = false;
  bool showEnabled = true;
  ProjectInfo? selectedProject;

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: BrowserSearchBar(
                onFilter: (s) {
                  setState(() {
                    searchText = s;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
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

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    controller: controller,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return BrowserViewElement(
                        index: index,
                        project: filteredProjects[index],
                        // selectedIndex: selectedIndex,
                        onTap: (e) {
                          setState(() {
                            showInfo = true;
                            infoVisible = true;
                          });

                          selectedProject = e;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Visibility(
          visible: infoVisible,
          maintainState: true,
          maintainAnimation: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedPadding(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastLinearToSlowEaseIn,
                padding: EdgeInsets.fromLTRB(
                  showInfo ? 0 : 200,
                  showInfo ? 0 : 200,
                  0,
                  0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastLinearToSlowEaseIn,
                  width: showInfo ? constraints.maxWidth : 200,
                  height: showInfo ? constraints.maxHeight : 200,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.fastLinearToSlowEaseIn,
                      opacity: showInfo ? 1.0 : 0.0,
                      child: Builder(
                        builder: (context) {
                          if (selectedProject != null) {
                            return InfoContentsWidget(
                              widget.app,
                              project: selectedProject!,
                              onClose: () {
                                setState(() {
                                  showInfo = false;
                                });

                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  if (!showInfo) {
                                    if (mounted) {
                                      setState(() {
                                        infoVisible = false;
                                      });
                                    }
                                  }
                                });
                              },
                            );
                          } else {
                            return Container();
                          }
                        },
                      )
                      /*child: ValueListenableBuilder<ProjectInfo?>(
                    valueListenable: selectedProject,
                    builder: (context, index, child) {
                      if (index < 0) {
                        index = 0;
                      }

                      return InfoContentsWidget(
                        widget.app,
                        onClose: () {
                          setState(() {
                            showInfo = false;
                          });

                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              if (!showInfo) {
                                setState(() {
                                  infoVisible = false;
                                });
                              }
                            },
                          );
                        },
                        instrument: widget.app.projects.value[index],
                      );
                    },
                  ),*/
                      ),
                ),
              );
            },
          ),
        ),
      ],
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
        Container(
          width: 200,
          height: 26,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: TextField(
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
        ),
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
                    onSelect: (s) {}),
                TagDropdown(
                    value: "Attributes",
                    tags: const [
                      "Analog",
                      "Generative",
                    ],
                    onSelect: (s) {}),
                TagDropdown(
                    value: "Other",
                    tags: const [
                      "Analog",
                      "Generative",
                    ],
                    onSelect: (s) {}),
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
          width: 290,
          height: mouseOver ? 300 : 200,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: mouseOver
                ? const Color.fromRGBO(70, 70, 70, 1.0)
                : const Color.fromRGBO(50, 50, 50, 1.0),
            boxShadow: [
              BoxShadow(
                blurRadius: 3,
                spreadRadius: 3,
                offset: const Offset(0, 3),
                color: Color.fromRGBO(0, 0, 0, mouseOver ? 0.3 : 0.0),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: Image.file(widget.project.image.value,
                          width: 290, fit: BoxFit.cover),
                    ),
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: mouseOver ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: () {
                            if (playing) {
                              controller.reverse();
                            } else {
                              controller.forward();
                            }

                            playing = !playing;
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: Color.fromRGBO(150, 150, 150, 0.5),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25))),
                            child: AnimatedIcon(
                              progress: controller,
                              icon: AnimatedIcons.play_pause,
                              color: const Color.fromRGBO(220, 220, 220, 1.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 56,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      widget.project.name.value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(220, 220, 220, 1.0)),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        widget.project.description.value.substring(
                                0,
                                min(40,
                                    widget.project.description.value.length)) +
                            (widget.project.description.value.length < 40
                                ? ""
                                : "..."),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey),
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

class BrowserListCard extends StatelessWidget {
  final String name;
  final String selected;
  final IconData icon;
  final bool visible;
  final bool dense;
  final void Function() onTap;

  BrowserListCard(
      {required this.name,
      required this.icon,
      required this.selected,
      required this.visible,
      required this.dense,
      required this.onTap})
      : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Card(
        margin: !dense
            ? const EdgeInsets.fromLTRB(5, 5, 5, 0)
            : const EdgeInsets.fromLTRB(5, 0, 5, 0),
        color: MyTheme.grey20,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          leading: dense ? Icon(icon, size: 18) : Icon(icon, size: 22),
          title: Text(
            name,
            style: dense
                ? const TextStyle(fontSize: 14)
                : const TextStyle(fontSize: 16),
          ),
          textColor: selected == name ? Colors.white : Colors.white30,
          iconColor: selected == name ? Colors.white : Colors.white30,
          tileColor: selected == name
              ? const Color.fromRGBO(255, 255, 255, 0.1)
              : MyTheme.grey20,
          dense: dense,
          minLeadingWidth: 26,
          onTap: onTap,
        ),
      ),
    );
  }
}

class Category {
  Category({required this.name, required this.elements});

  String name;
  List<CategoryElement> elements;
}

class CategoryElement {
  CategoryElement(this.name, {this.color, this.icon});

  String name;
  Color? color;
  Icon? icon;
}

class TagDropdown extends StatefulWidget {
  TagDropdown(
      {required this.value,
      required this.tags,
      required this.onSelect,
      this.width,
      this.height = 24,
      this.decoration = const BoxDecoration(
          color: Color.fromRGBO(20, 20, 20, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(3)))});

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
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12))),
                    child: Text(widget.value ?? "",
                        style: TextStyle(
                            fontSize: 12,
                            color: _isOpen
                                ? const Color.fromRGBO(20, 20, 20, 1.0)
                                : Colors.grey))))));
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
                      child: Stack(children: [
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
                                          color: const Color.fromRGBO(
                                              30, 30, 30, 1.0),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color.fromRGBO(
                                                  40, 40, 40, 1.0),
                                              width: 1.0)),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: widget.tags.map((name) {
                                            return TagDropdownElement(
                                              name: name,
                                              onSelect: widget.onSelect,
                                            );
                                          }).toList()),
                                    ))))
                      ]))));
        });
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                          width: 1.0,
                          color: !hovering
                              ? const Color.fromRGBO(60, 60, 60, 1.0)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                    ),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          )
                        ]))))));
  }
}
*/

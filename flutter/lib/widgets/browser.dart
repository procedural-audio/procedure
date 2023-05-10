import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../patch.dart';
import 'widget.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

/*double Function(RawWidgetPointer) ffiFaderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_fader_get_value")
    .asFunction();*/

List<List<double>> getWavetable() {
  List<List<double>> wavetable = [];

  for (int i = 0; i < 10; i++) {
    List<double> wave = [];

    for (int j = 0; j < 80; j++) {
      wave.add(sin((j.toDouble() / 80.0) * pi * 2 * i));
    }

    wavetable.add(wave);
  }

  return wavetable;
}

// TODO: Load in new isolate:
// https://www.didierboelens.com/2019/01/futures-isolates-event-loop/

class BrowserWidget extends ModuleWidget {
  BrowserWidget(RawNode m, RawWidget w) : super(m, w);

  @override
  Widget build(BuildContext context) {
    return BrowserOverlay();
  }
}

class BrowserOverlay extends StatefulWidget {
  BrowserOverlay({Key? key}) : super(key: key);

  @override
  _BrowserOverlay createState() => _BrowserOverlay();
}

class _BrowserOverlay extends State<BrowserOverlay> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  void _toggleDropdown({bool close = false}) async {
    if (_isOpen || close) {
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (entryContext) {
        return FocusScope(
          autofocus: true,
          node: _focusScopeNode,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _toggleDropdown(close: true);
            },
            onPanStart: (e) {
              _toggleDropdown(close: true);
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Positioned(
                    left: offset.dx,
                    top: offset.dy + 40.0,
                    child: Material(
                      color: Colors.transparent,
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        onPanStart: (e) {},
                        child: Container(
                          width: 600,
                          height: 400,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(20, 20, 20, 1.0),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            border: Border.all(
                              color: const Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                          ),
                          child: BrowserList(
                            rootDir: Directory(
                              "/Users/chasekanipe/Github/assets/wavetables/serum",
                            ),
                            onLoadFile: (file) {
                              print("Loading file $file");
                            },
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
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        children: [
          BrowserWidgetBar(
            name: "Name",
            author: "Chase Kanipe",
            onPressed: () {
              _toggleDropdown();
            },
          ),
          CustomPaint(
            painter: WavetablePainter(getWavetable()),
          ),
        ],
      ),
    );
  }
}

class BrowserWidgetBar extends StatelessWidget {
  BrowserWidgetBar({
    required this.name,
    required this.author,
    required this.onPressed,
  });

  String name;
  String author;
  void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BrowserBarElement(
              onPressed: () {
                onPressed();
              },
              icon: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.list,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30, width: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    " - " + author,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          /*const SizedBox(width: 5),
          BrowserBarElement(
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.grey,
            ),
            onPressed: () {
              print("Pressed here");
            },
          ),
          const SizedBox(width: 5),
          BrowserBarElement(
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
            onPressed: () {
              print("Pressed here");
            },
          ),*/
          const SizedBox(width: 5),
          BrowserBarElement(
            icon: const Icon(
              Icons.folder,
              color: Colors.blueAccent,
            ),
            onPressed: () {
              print("Pressed here");
            },
          )
        ],
      ),
    );
  }
}

class BrowserList extends StatefulWidget {
  BrowserList({required this.rootDir, required this.onLoadFile});

  Directory rootDir;
  void Function(File) onLoadFile;

  @override
  State<StatefulWidget> createState() => _BrowserList();
}

class _BrowserList extends State<BrowserList> {
  ScrollController controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: BrowserListDirectory(
          directory: widget.rootDir,
          onLoadFile: (f) => widget.onLoadFile(f),
        ),
      ),
    );
  }
}

class BrowserListDirectory extends StatefulWidget {
  BrowserListDirectory({
    required this.directory,
    required this.onLoadFile,
  }) : super(key: UniqueKey()) {
    scan();
  }

  Directory directory;
  void Function(File) onLoadFile;
  ValueNotifier<List<Directory>> subDirectories = ValueNotifier([]);
  ValueNotifier<List<File>> files = ValueNotifier([]);

  void scan() async {
    List<Directory> subDirs = [];
    List<File> fs = [];
    await for (var entity in directory.list()) {
      if (entity is Directory) {
        subDirs.add(entity);
        subDirectories.value = subDirs;
      } else if (entity is File) {
        fs.add(entity);
        files.value = fs;
      }
    }
  }

  @override
  State<StatefulWidget> createState() => _BrowserListDirectory();
}

class _BrowserListDirectory extends State<BrowserListDirectory> {
  dynamic selected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Directory>>(
      valueListenable: widget.subDirectories,
      builder: (context, subDirectories, child) {
        return ValueListenableBuilder<List<File>>(
          valueListenable: widget.files,
          builder: (context, files, child) {
            return Row(
              children: [
                Container(
                  width: 200,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Color.fromRGBO(30, 30, 30, 1.0),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          widget.directory.name + "/",
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView(
                          children: <Widget>[] +
                              subDirectories
                                  .map(
                                    (d) => BrowserListDirectoryElement(
                                      directory: d,
                                      selected: selected == d,
                                      onTap: () {
                                        setState(() {
                                          if (selected != d) {
                                            selected = d;
                                          } else {
                                            selected = null;
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList() +
                              files
                                  .map((e) => BrowserListFileElement(
                                        file: e,
                                        selected: selected == e,
                                        onTap: () {
                                          setState(() {
                                            if (selected != e) {
                                              selected = e;
                                            } else {
                                              selected = null;
                                            }
                                          });
                                        },
                                        onDoubleTap: () {
                                          print("Double tap");
                                          widget.onLoadFile(e);
                                        },
                                      ))
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (selected != null && selected is Directory) {
                      return BrowserListDirectory(
                        directory: selected!,
                        onLoadFile: (f) => widget.onLoadFile(f),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class BrowserListDirectoryElement extends StatefulWidget {
  BrowserListDirectoryElement({
    required this.directory,
    required this.selected,
    required this.onTap,
  }) : super(key: UniqueKey());

  Directory directory;
  bool selected;
  void Function() onTap;

  @override
  State<StatefulWidget> createState() => _BrowserListDirectoryElement();
}

class _BrowserListDirectoryElement extends State<BrowserListDirectoryElement> {
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
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          color: widget.selected
              ? const Color.fromRGBO(40, 40, 40, 1.0)
              : (hovering
                  ? const Color.fromRGBO(30, 30, 30, 1.0)
                  : const Color.fromRGBO(20, 20, 20, 1.0)),
          child: Text(
            widget.directory.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class BrowserListFileElement extends StatefulWidget {
  BrowserListFileElement({
    required this.file,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  }) : super(key: UniqueKey());

  File file;
  bool selected;
  void Function() onTap;
  void Function() onDoubleTap;

  @override
  State<StatefulWidget> createState() => _BrowserListFileElement();
}

class _BrowserListFileElement extends State<BrowserListFileElement> {
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
      child: Listener(
        behavior: HitTestBehavior.deferToChild,
        /*onPointerDown: (e) {
          widget.onTap();
        },*/
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onDoubleTap: () {
            widget.onDoubleTap();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            color: widget.selected
                ? const Color.fromRGBO(40, 40, 40, 1.0)
                : (hovering
                    ? const Color.fromRGBO(30, 30, 30, 1.0)
                    : const Color.fromRGBO(20, 20, 20, 1.0)),
            child: Row(
              children: [
                const Icon(
                  Icons.equalizer,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 200 - 20 - 60 - 6,
                  child: Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
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

class BrowserWidget2 extends ModuleWidget {
  BrowserWidget2(RawNode m, RawWidget w) : super(m, w);

  String name = "Tempered Felt Piano";
  String author = "Chase Kanipe";

  bool browserVisible = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Column(
            children: [
              Container(
                height: 30 + 8,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(20, 20, 20, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              browserVisible = !browserVisible;
                            });
                          },
                          child: Container(
                            width: 200,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.list,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 30, width: 4),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Visibility(
                                  visible: constraints.maxWidth > 500,
                                  child: Text(
                                    " - " + author,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          print("Pressed here");
                        },
                      ),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          print("Pressed here");
                        },
                      ),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                        icon: const Icon(
                          Icons.folder,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          print("Pressed here");
                        },
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    children[0],
                    Visibility(
                      visible: browserVisible,
                      child: BrowserList2(
                        extension: ".multisample",
                        path: "/Users/chasekanipe/Music/Decent Samples",
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BrowserBarElement extends StatefulWidget {
  BrowserBarElement({required this.icon, required this.onPressed});

  Widget icon;
  void Function() onPressed;

  @override
  State<StatefulWidget> createState() => _BrowserBarElement();
}

class _BrowserBarElement extends State<BrowserBarElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() {
        hovering = true;
      }),
      onExit: (e) => setState(() {
        hovering = false;
      }),
      child: Container(
        width: 30,
        decoration: BoxDecoration(
          color: hovering
              ? const Color.fromRGBO(50, 50, 50, 1.0)
              : const Color.fromRGBO(40, 40, 40, 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: widget.icon,
          onPressed: () {
            widget.onPressed();
          },
        ),
      ),
    );
  }
}

class BrowserList2 extends StatefulWidget {
  BrowserList2({required this.path, required this.extension});

  String path;
  String extension;

  @override
  State<StatefulWidget> createState() => _BrowserList2();
}

class _BrowserList2 extends State<BrowserList2> {
  List<String> categories = [
    "Basic",
    "Natural",
    "Processed",
    "Synthesizers",
    "Transform",
    "Imported"
  ];

  List<List<String>> presets = [
    [
      "Preset 1",
      "Preset 2",
      "Preset 3",
      "Preset 4",
      "Preset 5",
      "Preset 6",
      "Preset 7",
      "Preset 8"
    ],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
  ];

  int selectedCategory = 0;
  int selectedPreset = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> categoryWidgets = [];

    for (String category in categories) {
      bool selected = category == categories[selectedCategory];

      categoryWidgets.add(
        BrowserListCategory(
          name: category,
          selected: selected,
          onTap: () {
            setState(() {
              for (int i = 0; i < categories.length; i++) {
                if (categories[i] == category) {
                  setState(() {
                    selectedCategory = i;
                  });
                  break;
                }
              }
            });
          },
        ),
      );
    }

    List<Widget> elementWidgets = [];

    for (String element in presets[selectedCategory]) {
      elementWidgets.add(
        BrowserListElement(
          name: element,
          onTap: () {
            for (int i = 0; i < categories.length; i++) {
              if (presets[selectedCategory][i] == element) {
                setState(() {
                  selectedPreset = i;
                });
                break;
              }
            }
          },
        ),
      );

      elementWidgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Container(
            color: const Color.fromRGBO(50, 50, 50, 1.0),
            height: 1,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: categoryWidgets,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: elementWidgets,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BrowserListCategory extends StatelessWidget {
  BrowserListCategory(
      {required this.name, required this.selected, required this.onTap});

  String name;
  bool selected;
  void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Row(children: [
            Icon(
              Icons.person,
              color: selected ? Colors.white : Colors.grey,
              size: 14,
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ]),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.grey : Colors.grey.withAlpha(100),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class BrowserListElement extends StatelessWidget {
  BrowserListElement({required this.name, required this.onTap});

  String name;
  void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        height: 30,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class BrowserWidget3 extends ModuleWidget {
  BrowserWidget3(RawNode m, RawWidget w) : super(m, w);

  bool showPresets = false;
  bool presetsHovering = false;

  List<String> categories = [
    "Basic",
    "Natural",
    "Processed",
    "Synthesizers",
    "Transform",
    "Imported"
  ];

  List<List<String>> presets = [
    [
      "Preset 1",
      "Preset 2",
      "Preset 3",
      "Preset 4",
      "Preset 5",
      "Preset 6",
      "Preset 7",
      "Preset 8"
    ],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
    ["Preset 1", "Preset 2", "Preset 3", "Preset 4", "Preset 5"],
  ];

  List<List<double>> wavetable = getWavetable();

  int selectedCategory = 0;
  int selectedPreset = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> categoryWidgets = [];

    for (String category in categories) {
      bool selected = category == categories[selectedCategory];

      categoryWidgets.add(
        Padding(
          padding: const EdgeInsets.all(5),
          child: GestureDetector(
            onTap: () {
              setState(() {
                for (int i = 0; i < categories.length; i++) {
                  if (categories[i] == category) {
                    setState(() {
                      selectedCategory = i;
                    });
                    break;
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: selected ? Colors.white : Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? Colors.grey : Colors.grey.withAlpha(100),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> elementWidgets = [];

    for (String element in presets[selectedCategory]) {
      elementWidgets.add(
        GestureDetector(
          onTap: () {
            for (int i = 0; i < categories.length; i++) {
              if (presets[selectedCategory][i] == element) {
                setState(() {
                  selectedPreset = i;
                });
                break;
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            height: 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                element,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );

      elementWidgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Container(color: Colors.grey, height: 0.5)));
    }

    return Container(
      decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
                  child: Container(
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showPresets = !showPresets;
                        });
                      },
                      child: Icon(
                        showPresets ? Icons.waves : Icons.list,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                      child: MouseRegion(
                        onEnter: (e) {
                          setState(() {
                            presetsHovering = true;
                          });
                        },
                        onExit: (e) {
                          setState(() {
                            presetsHovering = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                          child: Container(
                            width: 100,
                            child: Row(
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.book,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Text(
                                    presets[selectedCategory][selectedPreset],
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                  child: Container(
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.grey,
                    ),
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                  child: Container(
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                  child: Container(
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.folder,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    color: const Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Visibility(
                    visible: showPresets,
                    child: Row(children: [
                      SingleChildScrollView(
                        controller: ScrollController(),
                        child: Container(
                          width: 150,
                          child: Column(
                            children: categoryWidgets,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: ScrollController(),
                          child: Column(
                            children: elementWidgets,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Visibility(
                    visible: !showPresets,
                    child: CustomPaint(
                      painter: WavetablePainter(wavetable),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavetablePainter extends CustomPainter {
  WavetablePainter(this.wavetable);

  List<List<double>> wavetable;

  @override
  void paint(Canvas canvas, ui.Size size) {
    List<List<Offset>> lines = [];

    int i = 0;
    for (var wave in wavetable) {
      double width = (size.width - i) * 4 / 5;
      double height = size.height / wavetable.length * 1.5;
      double offsetX = i * 3 + size.width / wavetable.length;
      double offsetY = (1 - i / wavetable.length) * size.height * 9 / 10;

      List<Offset> points = [Offset(0.0 + offsetX, offsetY)];
      int j = 0;

      for (var w in wave) {
        var curr =
            Offset(width / wave.length * j + offsetX, height / 2 * w + offsetY);

        points.add(curr);
        points.add(curr);
        j += 1;
      }

      lines.add(points);
      i += 1;
    }

    i = 0;
    for (var line in lines) {
      double mult = 1 - (i / lines.length).clamp(0.1, 1.0);

      // print(mult.toString());

      Paint paint = Paint()
        ..color = Colors.blue.withAlpha((255.0 * mult).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPoints(ui.PointMode.lines, line, paint);
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant WavetablePainter oldDelegate) {
    return wavetable != oldDelegate.wavetable;
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import '../patch.dart';
import 'widget.dart';
import '../main.dart';
import 'dart:ui' as ui;
import 'dart:ffi';
import '../core.dart';
import '../module.dart';

/*double Function(FFIWidgetPointer) ffiFaderGetValue = core
    .lookup<NativeFunction<Float Function(FFIWidgetPointer)>>(
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
  BrowserWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  String name = "Tempered Felt Piano";
  String author = "Chase Kanipe";

  bool browserVisible = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          decoration: const BoxDecoration(
              color: Color.fromRGBO(20, 20, 20, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Column(children: [
            Container(
                height: 30 + 8,
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(20, 20, 20, 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(children: [
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
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                  child: Row(children: [
                                    const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.list,
                                            size: 20, color: Colors.grey)),
                                    const SizedBox(height: 30, width: 4),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                    Visibility(
                                        visible: constraints.maxWidth > 500,
                                        child: Text(
                                          " - " + author,
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ))
                                  ])))),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.grey),
                          onPressed: () {
                            print("Pressed here");
                          }),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.grey),
                          onPressed: () {
                            print("Pressed here");
                          }),
                      const SizedBox(width: 4),
                      BrowserBarElement(
                          icon: const Icon(Icons.folder,
                              color: Colors.blueAccent),
                          onPressed: () {
                            print("Pressed here");
                          })
                    ]))),
            Expanded(
                child: Stack(children: [
              children[0],
              Visibility(
                visible: browserVisible,
                child: BrowserList(
                    extension: ".multisample",
                    path: "/Users/chasekanipe/Music/Decent Samples"),
              )
            ])),
          ]));
    });
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
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: widget.icon,
                onPressed: () {
                  widget.onPressed();
                })));
  }
}

class BrowserList extends StatefulWidget {
  BrowserList({required this.path, required this.extension});

  String path;
  String extension;

  @override
  State<StatefulWidget> createState() => _BrowserList();
}

class _BrowserList extends State<BrowserList> {
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

      categoryWidgets.add(BrowserListCategory(
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
          }));
    }

    List<Widget> elementWidgets = [];

    for (String element in presets[selectedCategory]) {
      elementWidgets.add(BrowserListElement(
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
          }));

      elementWidgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Container(
              color: const Color.fromRGBO(50, 50, 50, 1.0), height: 1)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: const BoxDecoration(
              color: Color.fromRGBO(20, 20, 20, 1.0),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
          child: Row(children: [
            Expanded(
                child: SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: categoryWidgets,
                    )))),
            const SizedBox(width: 10),
            Expanded(
                child: SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: elementWidgets,
                    ))))
          ]));
    });
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
                      color:
                          selected ? Colors.grey : Colors.grey.withAlpha(100),
                      width: 1.0)),
            )));
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ))));
  }
}

class BrowserWidget2 extends ModuleWidget {
  BrowserWidget2(App a, RawNode m, FFIWidget w) : super(a, m, w);

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

      categoryWidgets.add(Padding(
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
                child: Row(children: [
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
                ]),
                decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            selected ? Colors.grey : Colors.grey.withAlpha(100),
                        width: 1.0)),
              ))));
    }

    List<Widget> elementWidgets = [];

    for (String element in presets[selectedCategory]) {
      elementWidgets.add(GestureDetector(
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
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  )))));

      elementWidgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Container(color: Colors.grey, height: 0.5)));
    }

    return Container(
        decoration: BoxDecoration(
            color: const Color.fromRGBO(20, 20, 20, 1.0),
            borderRadius: BorderRadius.circular(5)),
        child: Column(children: [
          SizedBox(
              height: 40,
              child: Row(children: [
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
                            )),
                        color: const Color.fromRGBO(40, 40, 40, 1.0))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Color.fromRGBO(40, 40, 40, 1.0)),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  child: Container(
                                      width: 100,
                                      child: Row(children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            Icons.book,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 0, 0),
                                          child: Text(
                                            presets[selectedCategory]
                                                [selectedPreset],
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        )
                                      ])))),
                        ))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                    child: Container(
                        width: 30,
                        height: 30,
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.grey,
                        ),
                        color: const Color.fromRGBO(40, 40, 40, 1.0))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                    child: Container(
                        width: 30,
                        height: 30,
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        color: const Color.fromRGBO(40, 40, 40, 1.0))),
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
                        color: const Color.fromRGBO(40, 40, 40, 1.0))),
              ])),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: Stack(fit: StackFit.expand, children: [
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
                            child: Column(children: elementWidgets),
                          ),
                        ),
                      ]),
                    ),
                    Visibility(
                        visible: !showPresets,
                        child: CustomPaint(
                          painter: WavetablePainter(wavetable),
                        ))
                  ])))
        ]));
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

      print(mult.toString());

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

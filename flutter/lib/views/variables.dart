import 'dart:math';

// import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../patch/patch.dart';
import '../common.dart';

import 'dart:ffi';

class Vars extends StatefulWidget {
  Vars(this.app);

  App app;
  final ValueNotifier<List<VarEntry>> _entries = ValueNotifier([]);
  ValueNotifier<Var?> selectedVar = ValueNotifier(null);

  void newGroup() {
    print("TODO: New group");
  }

  void deleteVar(Var v) {
    print("TODO: Delete var");
  }

  void addVar(Var v) {
    _entries.value.add(VarEntry(variable: v, group: null));
    _entries.notifyListeners();
  }

  void addEntry(VarEntry v) {
    _entries.value.add(v);
    _entries.notifyListeners();
  }

  void insertEntry(int i, VarEntry v) {
    _entries.value.insert(i, v);
    _entries.notifyListeners();
  }

  VarEntry removeEntryAt(int i) {
    var temp = _entries.value.removeAt(i);
    _entries.notifyListeners();
    return temp;
  }

  int count() {
    return _entries.value.length;
  }

  @override
  _Vars createState() => _Vars();
}

class _Vars extends State<Vars> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 300,
        width: 300,
        decoration: const BoxDecoration(
            color: Color.fromRGBO(40, 40, 40, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: ValueListenableBuilder<List<VarEntry>>(
            valueListenable: widget._entries,
            builder: (context, entries, w) {
              return Row(children: [
                Expanded(
                    child: Theme(
                        data: ThemeData(canvasColor: Colors.transparent),
                        child: Column(children: [
                          Expanded(
                              child: ReorderableListView(
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }

                              var element = widget.removeEntryAt(oldIndex);
                              if (newIndex >= widget.count()) {
                                widget.addEntry(element);
                              } else {
                                widget.insertEntry(newIndex, element);
                              }

                              for (int i = 0;
                                  i < widget._entries.value.length;
                                  i++) {
                                var entry = widget._entries.value[i];
                                if (entry.variable != null) {
                                  entry.variable!.listIndex = i;
                                } else if (entry.group != null) {
                                  entry.group!.index = i;
                                } else {
                                  print("ERROR: UNREACHABLE ENTRY");
                                }
                              }
                            },
                            children: entries,
                          )),
                          SizedBox(
                              height: 30,
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: IconButton(
                                        icon: const Icon(Icons.lock),
                                        color: Colors.grey,
                                        iconSize: 16,
                                        onPressed: () {
                                          print("LOCKY THINGY");
                                        },
                                      )),
                                  SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: IconButton(
                                        icon: const Icon(Icons.add),
                                        color: Colors.grey,
                                        iconSize: 16,
                                        onPressed: () {
                                          var name = "New Variable";
                                          bool done = false;
                                          int varIndex = 1;

                                          while (!done) {
                                            done = true;
                                            for (int i = 0;
                                                i <
                                                    widget
                                                        ._entries.value.length;
                                                i++) {
                                              var entry =
                                                  widget._entries.value[i];

                                              if (entry.variable != null) {
                                                if (entry
                                                        .variable!.name.value ==
                                                    name) {
                                                  done = false;
                                                  varIndex += 1;
                                                  name = name.substring(0, 12) +
                                                      " " +
                                                      varIndex.toString();
                                                }
                                              }
                                            }
                                          }

                                          widget.addVar(Var(
                                            app: widget.app,
                                            name: ValueNotifier(name),
                                            listIndex: widget.count(),
                                            selectedVar: widget.selectedVar,
                                            id: 0,
                                            notifier: ValueNotifier(0.0),
                                          ));
                                        },
                                      )),
                                  SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: IconButton(
                                        icon: const Icon(Icons.folder_copy),
                                        color: Colors.grey,
                                        iconSize: 16,
                                        onPressed: () {
                                          widget.newGroup();
                                        },
                                      )),
                                ],
                              ))
                        ]))),
                Expanded(
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(10))),
                        child: ValueListenableBuilder<Var?>(
                            valueListenable: widget.selectedVar,
                            builder: (context, selectedVar, child) {
                              if (selectedVar == null) {
                                return const Center(
                                  child: Text(
                                    "Variable Details",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                );
                              } else {
                                return SingleChildScrollView(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                      const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            "Variable Details",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15),
                                          )),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                const Text(
                                                  "Name",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                                Container(
                                                  width: 140,
                                                  height: 28,
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromRGBO(
                                                              20, 20, 20, 1.0),
                                                      border: Border.all(
                                                          color: const Color
                                                              .fromRGBO(
                                                              80, 80, 80, 1.0),
                                                          width: 1),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  5))),
                                                  child: EditableText(
                                                    focusNode: FocusNode(),
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white),
                                                    cursorColor: Colors.blue,
                                                    backgroundCursorColor:
                                                        Colors.red,
                                                    controller:
                                                        TextEditingController(
                                                            text: selectedVar
                                                                .name.value),
                                                    onChanged: (value) {
                                                      selectedVar.name.value =
                                                          value;
                                                    },
                                                  ),
                                                ),
                                              ])),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Type",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                                SearchableDropdown(
                                                    width: 140,
                                                    height: 30,
                                                    value: selectedVar.notifier
                                                        .value.runtimeType
                                                        .toString(),
                                                    categories: [
                                                      Category(
                                                          name: "Basic",
                                                          elements: [
                                                            CategoryElement(
                                                                "Boolean"),
                                                            CategoryElement(
                                                                "Float"),
                                                            CategoryElement(
                                                                "Integer")
                                                          ]),
                                                      Category(
                                                          name: "Files",
                                                          elements: [
                                                            CategoryElement(
                                                                "Sample"),
                                                            CategoryElement(
                                                                "Multi-sample"),
                                                            CategoryElement(
                                                                "Wavetable")
                                                          ]),
                                                    ],
                                                    onSelect: (s) {
                                                      if (s == "Boolean") {
                                                        selectedVar.notifier
                                                            .value = false;
                                                      } else if (s == "Float") {
                                                        selectedVar.notifier
                                                            .value = false;
                                                        selectedVar.notifier
                                                            .value = 0.0;
                                                      } else if (s ==
                                                          "Integer") {
                                                        selectedVar.notifier
                                                            .value = false;
                                                        selectedVar.notifier
                                                            .value = 0.toInt();
                                                      } else {
                                                        print(
                                                            "Unknown supported type");
                                                      }

                                                      setState(() {});
                                                      print("Type is " +
                                                          selectedVar.notifier
                                                              .value.runtimeType
                                                              .toString());
                                                    })
                                              ])),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Value",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                                ValueListenableBuilder(
                                                    valueListenable:
                                                        selectedVar.notifier,
                                                    builder: (context, value,
                                                        child) {
                                                      return Text(
                                                        formatValue(value),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14),
                                                      );
                                                    })
                                              ])),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Parameter Assignments",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  height: 100,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Color.fromRGBO(
                                                              30,
                                                              30,
                                                              30,
                                                              1.0),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5))),
                                                )
                                              ])),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Widget Assignments",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  height: 100,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Color.fromRGBO(
                                                              30,
                                                              30,
                                                              30,
                                                              1.0),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5))),
                                                )
                                              ])),
                                      const Divider(
                                        color: Color.fromRGBO(30, 30, 30, 1.0),
                                        height: 1,
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  border: Border.all(
                                                      width: 2,
                                                      color: Colors.red)),
                                              child: TextButton(
                                                onPressed: () {
                                                  widget.deleteVar(selectedVar);
                                                },
                                                child: const Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14),
                                                ),
                                              ))),
                                    ]));
                              }
                            })))
              ]);
            }));
  }
}

class VarEntry extends StatefulWidget {
  VarEntry({required this.variable, required this.group})
      : super(key: UniqueKey());
  Var? variable;
  VarGroup? group;

  @override
  _VarEntry createState() => _VarEntry();
}

class _VarEntry extends State<VarEntry> {
  @override
  Widget build(BuildContext context) {
    if (widget.group != null) {
      return widget.group!;
    } else if (widget.variable != null) {
      return widget.variable!;
    } else {
      print("ERROR: UNREACHABLE ENTRY TYPE");
      return Container();
    }
  }
}

class VarGroup extends StatefulWidget {
  VarGroup({
    required this.app,
    required this.name,
    required this.vars,
    required this.index,
  }) : super(key: UniqueKey());
  String name;
  List<Var> vars;
  int index;
  App app;

  @override
  _VarGroup createState() => _VarGroup();
}

class _VarGroup extends State<VarGroup> {
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
                    height: widget.vars.length * 30 + 10,
                    child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          var element = widget.vars.removeAt(oldIndex);
                          if (newIndex >= widget.vars.length) {
                            widget.vars.add(element);
                          } else {
                            widget.vars.insert(newIndex, element);
                          }

                          for (int i = 0; i < widget.vars.length; i++) {
                            widget.vars[i].listIndex = i;
                          }
                        },
                        children: widget.vars),
                  )))
        ]));
  }
}

class VarAssignment {
  VarAssignment({required this.moduleId, required this.widgetIndex});

  int moduleId;
  int widgetIndex;
}

class Var extends StatefulWidget {
  Var({
    required this.app,
    required this.id,
    required this.name,
    required this.notifier,
    required this.selectedVar,
    required this.listIndex,
  }) : super(key: UniqueKey());

  App app;
  int id;
  ValueNotifier<String> name;
  ValueNotifier<dynamic> notifier;
  ValueNotifier<Var?> selectedVar;
  ValueNotifier<List<VarAssignment>> assignments = ValueNotifier([]);
  int listIndex;

  @override
  _Var createState() => _Var();
}

class _Var extends State<Var> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    String typeName = "Unknown";

    if (widget.notifier.value.runtimeType == double) {
      typeName = "double";
    } else if (widget.notifier.value.runtimeType == bool) {
      typeName = "bool";
    }

    var w = ValueListenableBuilder<Var?>(
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
                child: Draggable<Var>(
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
}

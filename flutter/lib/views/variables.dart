import 'dart:math';

// import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../host.dart';
import '../common.dart';

import 'dart:ffi';

const radius = 15.0;

/*int Function(FFIHost) ffiHostVarsGetTabCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_vars_get_tab_count")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostVarsTabGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_vars_tab_get_name")
    .asFunction();*/

int Function(FFIHost) ffiHostVarsGetEntryCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_vars_get_entry_count")
    .asFunction();

int Function(FFIHost, int) ffiHostVarsEntryGetType = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_vars_entry_get_type")
    .asFunction();

int Function(FFIHost, int) ffiHostVarsEntryGetId = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64)>>(
        "ffi_host_vars_entry_get_id")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostVarsGroupGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_vars_group_get_name")
    .asFunction();

int Function(FFIHost, int) ffiHostVarsGroupGetVarCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64)>>(
        "ffi_host_vars_group_get_var_count")
    .asFunction();

int Function(FFIHost, int, int) ffiHostVarsGroupVarGetId = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_group_var_get_id")
    .asFunction();

int Function(FFIHost, int) ffiHostVarGetType = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64)>>(
        "ffi_host_var_get_type")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostVarGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_var_get_name")
    .asFunction();

void Function(FFIHost, int, Pointer<Utf8>) ffiHostVarRename = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Pointer<Utf8>)>>(
        "ffi_host_var_rename")
    .asFunction();

void Function(FFIHost, int, int) ffiHostVarSetType = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Int32)>>(
        "ffi_host_var_set_type")
    .asFunction();

void Function(FFIHost, int) ffiHostVarDelete = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64)>>(
        "ffi_host_var_delete")
    .asFunction();

void Function(FFIHost) ffiHostVarsAddVar = core
    .lookup<NativeFunction<Void Function(FFIHost)>>("ffi_host_vars_add_var")
    .asFunction();

void Function(FFIHost) ffiHostVarsAddGroup = core
    .lookup<NativeFunction<Void Function(FFIHost)>>("ffi_host_vars_add_group")
    .asFunction();

double Function(FFIHost, int) ffiHostVarGetFloat = core
    .lookup<NativeFunction<Float Function(FFIHost, Int64)>>(
        "ffi_host_var_get_float")
    .asFunction();

void Function(FFIHost, int, double) ffiHostVarSetFloat = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Float)>>(
        "ffi_host_var_set_float")
    .asFunction();

bool Function(FFIHost, int) ffiHostVarGetBool = core
    .lookup<NativeFunction<Bool Function(FFIHost, Int64)>>(
        "ffi_host_var_get_bool")
    .asFunction();

void Function(FFIHost, int, bool) ffiHostVarSetBool = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Bool)>>(
        "ffi_host_var_set_bool")
    .asFunction();

void Function(FFIHost, int, int) ffiHostVarsEntryReorder = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_entry_reorder")
    .asFunction();

void Function(FFIHost, int, int, int) ffiHostVarsGroupVarReorder = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Int64, Int64)>>(
        "ffi_host_vars_group_var_reorder")
    .asFunction();

class Vars extends StatefulWidget {
  Vars(this.host);

  Host host;
  ValueNotifier<List<VarEntry>> entries = ValueNotifier([]);
  ValueNotifier<Var?> selectedVar = ValueNotifier(null);

  void refresh() {
    entries.value.clear();

    List<VarEntry> tempEntries = [];
    int entryCount = ffiHostVarsGetEntryCount(host.host);

    for (int j = 0; j < entryCount; j++) {
      int entryType = ffiHostVarsEntryGetType(host.host, j);

      if (entryType == 0) {
        int id = ffiHostVarsEntryGetId(host.host, j);
        int varType = ffiHostVarGetType(host.host, id);

        dynamic value;

        if (varType == 0) {
          value = ffiHostVarGetFloat(host.host, id);
        } else if (varType == 1) {
          value = ffiHostVarGetBool(host.host, id);
        } else {
          print("TYPE NOT SUPPORTED IN VAR GETTER");
        }

        var rawName = ffiHostVarGetName(host.host, id);
        String name = rawName.toDartString();
        calloc.free(rawName);

        print(name + ": " + id.toString());

        tempEntries.add(VarEntry(
            variable: Var(
              host: host,
              id: id,
              name: name,
              notifier: ValueNotifier(value),
              listIndex: tempEntries.length,
            ),
            group: null));
      } else if (entryType == 1) {
        var rawName = ffiHostVarsGroupGetName(host.host, j);
        String name = rawName.toDartString();
        calloc.free(rawName);

        List<Var> vars = [];
        int varCount = ffiHostVarsGroupGetVarCount(host.host, j);

        for (int k = 0; k < varCount; k++) {
          int id = ffiHostVarsGroupVarGetId(host.host, j, k);
          int varType = ffiHostVarGetType(host.host, id);

          dynamic value;

          if (varType == 0) {
            value = ffiHostVarGetFloat(host.host, id);
          } else if (varType == 1) {
            value = ffiHostVarGetBool(host.host, id);
          } else {
            print("TYPE NOT SUPPORTED IN VAR GETTER");
          }

          var rawName = ffiHostVarGetName(host.host, id);
          String name = rawName.toDartString();
          calloc.free(rawName);

          vars.add(Var(
            host: host,
            id: id,
            name: name,
            notifier: ValueNotifier(value),
            listIndex: k,
          ));
        }

        tempEntries.add(VarEntry(
            variable: null,
            group: VarGroup(host: host, name: name, vars: vars, index: j)));
      } else {
        print("ERROR: UNSUPPORTED VAR TYPE");
      }
    }

    entries.value = tempEntries;
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
            valueListenable: widget.host.vars.entries,
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
                              print("Reordering from " +
                                  oldIndex.toString() +
                                  " " +
                                  newIndex.toString());

                              ffiHostVarsEntryReorder(
                                  widget.host.host, oldIndex, newIndex);

                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }

                              var element = widget.host.vars.entries.value
                                  .removeAt(oldIndex);
                              if (newIndex >=
                                  widget.host.vars.entries.value.length) {
                                widget.host.vars.entries.value.add(element);
                              } else {
                                widget.host.vars.entries.value
                                    .insert(newIndex, element);
                              }

                              for (int i = 0;
                                  i < widget.host.vars.entries.value.length;
                                  i++) {
                                widget.host.vars.entries.value[i].group?.index =
                                    i;
                                widget.host.vars.entries.value[i].variable
                                    ?.listIndex = i;
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
                                          ffiHostVarsAddVar(widget.host.host);
                                          widget.host.vars.refresh();
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
                                          ffiHostVarsAddGroup(widget.host.host);
                                          widget.host.vars.refresh();
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
                            valueListenable: widget.host.vars.selectedVar,
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
                                    child: Column(children: [
                                  const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        "Variable Details",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15),
                                      )),
                                  const Divider(
                                    color: Color.fromRGBO(30, 30, 30, 1.0),
                                    height: 1,
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      20, 20, 20, 1.0),
                                                  border: Border.all(
                                                      color:
                                                          const Color.fromRGBO(
                                                              80, 80, 80, 1.0),
                                                      width: 1),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5))),
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
                                                        text: selectedVar.name),
                                                onChanged: (value) {
                                                  print(value);
                                                  var rawName =
                                                      value.toNativeUtf8();
                                                  ffiHostVarRename(
                                                      widget.host.host,
                                                      selectedVar.id,
                                                      rawName);
                                                  calloc.free(rawName);

                                                  selectedVar.name = value;
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
                                              MainAxisAlignment.spaceBetween,
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
                                                value: selectedVar
                                                    .notifier.value.runtimeType
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
                                                  print("Change type");
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Value",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              selectedVar.notifier.value
                                                  .toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
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
                                              "Parameter Assignments",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              height: 100,
                                              decoration: const BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      30, 30, 30, 1.0),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(5))),
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
                                              decoration: const BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      30, 30, 30, 1.0),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(5))),
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
                                                  width: 2, color: Colors.red)),
                                          child: TextButton(
                                            onPressed: () {
                                              print("Delete thing");
                                              widget.selectedVar.value = null;
                                              ffiHostVarDelete(widget.host.host,
                                                  selectedVar.id);
                                              widget.host.vars.refresh();
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
  VarGroup(
      {required this.host,
      required this.name,
      required this.vars,
      required this.index})
      : super(key: UniqueKey());
  String name;
  List<Var> vars;
  int index;
  Host host;

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
                          print("Reordering from " +
                              oldIndex.toString() +
                              " " +
                              newIndex.toString());

                          ffiHostVarsGroupVarReorder(widget.host.host,
                              widget.index, oldIndex, newIndex);

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

class Var extends StatefulWidget {
  Var(
      {required this.host,
      required this.id,
      required this.name,
      required this.notifier,
      required this.listIndex})
      : super(key: UniqueKey());

  Host host;
  int id;
  String name;
  ValueNotifier<dynamic> notifier;
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

    return LayoutBuilder(builder: (context, constraints) {
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
                    if (widget == widget.host.vars.selectedVar.value) {
                      widget.host.vars.selectedVar.value = null;
                    } else {
                      widget.host.vars.selectedVar.value = widget;
                    }
                  },
                  child: ValueListenableBuilder<Var?>(
                      valueListenable: widget.host.vars.selectedVar,
                      builder: (context, selectedVar, child) {
                        return Container(
                          height: 30,
                          decoration: BoxDecoration(
                              color: selectedVar == widget
                                  ? (hovering
                                      ? const Color.fromRGBO(90, 90, 90, 1.0)
                                      : const Color.fromRGBO(80, 80, 80, 1.0))
                                  : (hovering
                                      ? const Color.fromRGBO(70, 70, 70, 1.0)
                                      : const Color.fromRGBO(60, 60, 60, 1.0)),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5))),
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
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                ),
                              ),
                              Expanded(
                                  child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Text(widget.name,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              )),
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Text(widget.notifier.value.toString(),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
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
                      }))));
    });
  }
}

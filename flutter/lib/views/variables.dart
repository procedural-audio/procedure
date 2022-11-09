import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../host.dart';

import 'dart:ffi';

const radius = 15.0;

int Function(FFIHost) ffiHostVarsGetTabCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_vars_get_tab_count")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostVarsTabGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_vars_tab_get_name")
    .asFunction();

int Function(FFIHost, int) ffiHostVarsTabGetEntryCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64)>>(
        "ffi_host_vars_tab_get_entry_count")
    .asFunction();

int Function(FFIHost, int, int) ffiHostVarsTabEntryGetType = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_tab_entry_get_type")
    .asFunction();

int Function(FFIHost, int, int) ffiHostVarsTabEntryGetId = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_tab_entry_get_id")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int, int) ffiHostVarsTabGroupGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_tab_group_get_name")
    .asFunction();

int Function(FFIHost, int, int) ffiHostVarsTabGroupGetVarCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64, Int64)>>(
        "ffi_host_vars_tab_group_get_var_count")
    .asFunction();

int Function(FFIHost, int, int, int) ffiHostVarsTabGroupVarGetId = core
    .lookup<NativeFunction<Int64 Function(FFIHost, Int64, Int64, Int64)>>(
        "ffi_host_vars_tab_group_var_get_id")
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

void Function(FFIHost, int) ffiHostVarsTabAddVar = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64)>>(
        "ffi_host_vars_tab_add_var")
    .asFunction();

void Function(FFIHost, int) ffiHostVarsTabGroupAddVar = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64)>>(
        "ffi_host_vars_tab_group_add_var")
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

class Vars {
  Vars(this.host);

  Host host;
  ValueNotifier<List<VarTab>> tabs = ValueNotifier([]);

  void refresh() {
    tabs.value.clear();

    List<VarTab> tempTabs = [];
    int tabCount = ffiHostVarsGetTabCount(host.host);

    for (int i = 0; i < tabCount; i++) {
      var rawName = ffiHostVarsTabGetName(host.host, i);
      String name = rawName.toDartString();
      calloc.free(rawName);

      List<VarEntry> entries = [];
      int entryCount = ffiHostVarsTabGetEntryCount(host.host, i);

      for (int j = 0; j < entryCount; j++) {
        int type = ffiHostVarsTabEntryGetType(host.host, i, j);

        if (type == 0) {
          int id = ffiHostVarsTabEntryGetId(host.host, i, j);

          dynamic value;

          if (type == 0) {
            value = ffiHostVarGetFloat(host.host, id);
          } else if (type == 1) {
            value = ffiHostVarGetBool(host.host, id);
          } else {
            print("TYPE NOT SUPPORTED IN VAR GETTER");
          }

          var rawName = ffiHostVarGetName(host.host, i);
          String name = rawName.toDartString();
          calloc.free(rawName);

          entries.add(VarEntry(
              variable: Var(
                host: host,
                id: id,
                name: name,
                notifier: ValueNotifier(value),
              ),
              group: null));
        } else if (type == 1) {
          var rawName = ffiHostVarsTabGroupGetName(host.host, i, j);
          String name = rawName.toDartString();
          calloc.free(rawName);

          List<Var> vars = [];
          int varCount = ffiHostVarsTabGroupGetVarCount(host.host, i, j);

          for (int k = 0; k < varCount; k++) {
            int id = ffiHostVarsTabGroupVarGetId(host.host, i, j, k);

            dynamic value;

            if (type == 0) {
              value = ffiHostVarGetFloat(host.host, id);
            } else if (type == 1) {
              value = ffiHostVarGetBool(host.host, id);
            } else {
              print("TYPE NOT SUPPORTED IN VAR GETTER");
            }

            var rawName = ffiHostVarGetName(host.host, i);
            String name = rawName.toDartString();
            calloc.free(rawName);

            vars.add(Var(
              host: host,
              id: id,
              name: name,
              notifier: ValueNotifier(value),
            ));
          }

          entries.add(VarEntry(
              variable: null, group: VarGroup(name: name, vars: vars)));
        } else {
          print("ERROR: UNSUPPORTED VAR TYPE");
        }
      }

      tempTabs.add(VarTab(name: name, entries: entries));
    }

    tabs.value = tempTabs;
  }
}

class VariablesWidget extends StatefulWidget {
  VariablesWidget(this.host);

  Host host;

  @override
  _VariablesWidget createState() => _VariablesWidget();
}

class _VariablesWidget extends State<VariablesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 300,
        width: 300,
        decoration: const BoxDecoration(
            color: Color.fromRGBO(40, 40, 40, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: ValueListenableBuilder<List<VarTab>>(
            valueListenable: widget.host.vars.tabs,
            builder: (context, tabs, w) {
              return DefaultTabController(
                  length: tabs.length,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                          height: 35,
                          width: 300,
                          child: TabBar(
                            tabs:
                                tabs.map((tab) => Tab(text: tab.name)).toList(),
                          )),
                      Expanded(
                          child: TabBarView(
                              children: tabs.map((tab) => tab).toList()))
                    ],
                  ));
            }));
  }
}

class VarTab extends StatefulWidget {
  VarTab({required this.name, required this.entries});
  String name;
  List<VarEntry> entries;

  @override
  _VarTab createState() => _VarTab();
}

class _VarTab extends State<VarTab> {
  @override
  Widget build(BuildContext context) {
    return Column(children: widget.entries);
  }
}

class VarEntry extends StatefulWidget {
  VarEntry({required this.variable, required this.group});
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
  VarGroup({required this.name, required this.vars});
  String name;
  List<Var> vars;

  @override
  _VarGroup createState() => _VarGroup();
}

class _VarGroup extends State<VarGroup> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
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
            child: Container(
                height: 40,
                color: hovering
                    ? const Color.fromRGBO(70, 70, 70, 1.0)
                    : const Color.fromRGBO(60, 60, 60, 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(
                      width: 40,
                      child: Icon(Icons.folder, size: 18, color: Colors.blue),
                    ),
                    SizedBox(
                        width: 200,
                        child: Text(widget.name,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white))),
                  ],
                ))));
  }
}

class Var extends StatefulWidget {
  Var(
      {required this.host,
      required this.id,
      required this.name,
      required this.notifier});

  Host host;
  int id;
  String name;
  ValueNotifier<dynamic> notifier;

  @override
  _Var createState() => _Var();
}

class _Var extends State<Var> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    double width = 600.0 / 4.0;

    String typeName = "Unknown";

    if (widget.notifier.value.runtimeType == double) {
      typeName = "double";
    } else if (widget.notifier.value.runtimeType == bool) {
      typeName = "bool";
    }

    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
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
            child: Container(
              height: 30,
              color: hovering
                  ? const Color.fromRGBO(60, 60, 60, 1.0)
                  : const Color.fromRGBO(50, 50, 50, 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: width,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                        ),
                        const SizedBox(width: 10),
                        Text(typeName)
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    width: width,
                    child: Text(widget.name),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    width: width,
                    child: Text("Description goes here"),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    width: width,
                    child: Text("Value Stuff"),
                  ),
                ],
              ),
            )));
    /*return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: Container(
                width: null,
                height: 30,
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: const Color.fromRGBO(80, 80, 80, 1.0),
                    borderRadius: BorderRadius.circular(5)),
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  VarTypeDropdown(widget, widget.host),
                  const SizedBox(width: 10),
                  Text("Should Get Name Here",
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w300)),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  ValueListenableBuilder<dynamic>(
                      valueListenable: widget.notifier,
                      builder: (context, value, w) {
                        return Text(
                            value
                                .toString()
                                .substring(0, min(value.toString().length, 8)),
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w300));
                      }),
                  const SizedBox(width: 10),
                  VarDeleteButton(
                    onTap: () {
                      /*ffiHostDeleteVar(
                          widget.host.host, widget.name.toNativeUtf8());
                      widget.host.refreshVariables();
                      widget.host.vars.notifyListeners();*/
                      print("Delete var here");
                    },
                  )
                ]))));*/
  }
}

class VarsGroup extends StatefulWidget {
  VarsGroup(this.name, this.host, {this.vars = const []});

  String name;
  List<Var> vars;
  Host host;

  @override
  _VarsGroup createState() => _VarsGroup();
}

class _VarsGroup extends State<VarsGroup> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
        child: Column(children: [
          Container(
              height: 30,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(60, 60, 60, 1.0),
                  borderRadius: expanded
                      ? const BorderRadius.vertical(top: Radius.circular(5))
                      : const BorderRadius.all(Radius.circular(5))),
              child: Stack(
                children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      )),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 10, 0),
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w300),
                        ),
                      )),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: IconButton(
                          padding: const EdgeInsets.all(0),
                          onPressed: () {
                            /*ffiHostAddVar(widget.host.host, 0,
                                widget.name.toNativeUtf8());
                            widget.host.refreshVariables();
                            widget.host.vars.notifyListeners();*/
                            print("Add var here");
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      )),
                ],
              )),
          AnimatedSize(
              curve: Curves.fastLinearToSlowEaseIn,
              duration: const Duration(milliseconds: 500),
              child: Container(
                height: expanded ? null : 0,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                decoration: BoxDecoration(
                    color: const Color.fromRGBO(60, 60, 60, 1.0),
                    borderRadius: expanded
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(5))
                        : const BorderRadius.all(Radius.circular(5))),
                child: Column(children: widget.vars),
              ))
        ]));
  }
}

class VarDeleteButton extends StatefulWidget {
  VarDeleteButton({required this.onTap});

  void Function() onTap;

  @override
  State<VarDeleteButton> createState() => _VarDeleteButton();
}

class _VarDeleteButton extends State<VarDeleteButton> {
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
            child: Container(
              width: 30,
              height: 30,
              child: Icon(
                Icons.close,
                size: 16,
                color: hovering ? Colors.white : Colors.grey,
              ),
              decoration: BoxDecoration(
                  color: hovering
                      ? const Color.fromRGBO(100, 100, 100, 1.0)
                      : Colors.red.withOpacity(0.0),
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(5))),
            )));
  }
}

class VarTypeDropdown extends StatefulWidget {
  VarTypeDropdown(this.v, this.host);

  Var v;
  Host host;

  @override
  State<VarTypeDropdown> createState() => _VarTypeDropdown();
}

class _VarTypeDropdown extends State<VarTypeDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  Animation<double>? _rotateAnimation;

  TextEditingController controller = TextEditingController(text: "hello");

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
  }

  /*@override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
    Color color = Colors.black;

    if (widget.v.notifier.value is double) {
      color = Colors.green;
    } else if (widget.v.notifier.value is bool) {
      color = Colors.red;
    }

    return CompositedTransformTarget(
        link: _layerLink,
        child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(5)),
            child: GestureDetector(
              onTap: _toggleDropdown,
            )));
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    var topOffset = offset.dy + size.height + 5;

    print("Create overlay entry");

    return OverlayEntry(
        maintainState: false,
        opaque: false,
        builder: (entryContext) {
          print("Overlay entry build");

          /*return Material(
          key: UniqueKey(),
          child: TextField(
            autofocus: true,
            focusNode: focusNode,
            controller: controller,
        ));*/

          /*return FocusScope(
          node: _focusScopeNode,
          child: Material(
            child: TextField(
              controller: controller,
            )
          )
        );*/

          return FocusScope(
              autofocus: true,
              node: _focusScopeNode,
              child: GestureDetector(
                  onTap: () {
                    _toggleDropdown(close: true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Stack(children: [
                    Positioned(
                        left: offset.dx,
                        top: topOffset,
                        child: CompositedTransformFollower(
                            offset: Offset(0, size.height + 5),
                            link: _layerLink,
                            showWhenUnlinked: false,
                            child: Material(
                                elevation: 0,
                                borderRadius: BorderRadius.zero,
                                color: Colors.transparent,
                                child: SizeTransition(
                                    axisAlignment: 1,
                                    sizeFactor: _expandAnimation!,
                                    // child: widget.child,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                                120, 120, 120, 1.0),
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              VarDropdownTypeElement(
                                                  Icons.numbers,
                                                  "Float",
                                                  0,
                                                  Colors.green,
                                                  widget.v),
                                              VarDropdownTypeElement(
                                                  Icons.select_all,
                                                  "Boolean",
                                                  1,
                                                  Colors.red,
                                                  widget.v),
                                            ]))))))
                  ])));
        });
  }

  void _toggleDropdown({bool close = false}) async {
    if (_isOpen || close) {
      await _animationController?.reverse();
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }
}

class VarDropdownTypeElement extends StatefulWidget {
  VarDropdownTypeElement(
      this.iconData, this.text, this.type, this.color, this.v);

  IconData iconData;
  String text;
  int type;
  Color color;
  Var v;

  @override
  State<VarDropdownTypeElement> createState() => _VarDropdownTypeElement();
}

class _VarDropdownTypeElement extends State<VarDropdownTypeElement> {
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
              /*var rawName = widget.v.name.toNativeUtf8();
              ffiHostVarSetType(widget.v.host.host, rawName, widget.type);
              calloc.free(rawName);
              widget.v.host.refreshVariables();*/
              print("Should change a thing here");
            },
            child: Container(
                height: 30,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                color: hovering
                    ? const Color.fromRGBO(140, 140, 140, 1.0)
                    : const Color.fromRGBO(120, 120, 120, 1.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5))),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w300))
                    ]))));
  }
}

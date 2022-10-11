import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../host.dart';

import 'dart:ffi';

const radius = 15.0;

int Function(FFIHost) ffiHostGetVarsCount = core
    .lookup<NativeFunction<Int64 Function(FFIHost)>>(
        "ffi_host_get_vars_count")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostGetVarName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_get_var_name")
    .asFunction();

Pointer<Utf8> Function(FFIHost, int) ffiHostGetVarGroup = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIHost, Int64)>>(
        "ffi_host_get_var_group")
    .asFunction();

int Function(FFIHost, int) ffiHostGetVarValueType = core
    .lookup<NativeFunction<Int32 Function(FFIHost, Int64)>>(
        "ffi_host_get_var_value_type")
    .asFunction();

double Function(FFIHost, int) ffiHostGetVarValueFloat = core
    .lookup<NativeFunction<Float Function(FFIHost, Int64)>>(
        "ffi_host_get_var_value_float")
    .asFunction();

bool Function(FFIHost, int) ffiHostGetVarValueBool = core
    .lookup<NativeFunction<Bool Function(FFIHost, Int64)>>(
        "ffi_host_get_var_value_bool")
    .asFunction();

void Function(FFIHost, int, double) ffiHostSetVarValueFloat = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Float)>>(
        "ffi_host_set_var_value_float")
    .asFunction();

void Function(FFIHost, int, bool) ffiHostSetVarValueBool = core
    .lookup<NativeFunction<Void Function(FFIHost, Int64, Bool)>>(
        "ffi_host_set_var_value_bool")
    .asFunction();

void Function(FFIHost, int, Pointer<Utf8>) ffiHostAddVar = core
    .lookup<NativeFunction<Void Function(FFIHost, Int32, Pointer<Utf8>)>>(
        "ffi_host_add_var")
    .asFunction();

void Function(FFIHost, Pointer<Utf8>, Pointer<Utf8>) ffiHostRenameVar = core
    .lookup<NativeFunction<Void Function(FFIHost, Pointer<Utf8>, Pointer<Utf8>)>>(
        "ffi_host_rename_var")
    .asFunction();

void Function(FFIHost, Pointer<Utf8>) ffiHostDeleteVar = core
    .lookup<NativeFunction<Void Function(FFIHost, Pointer<Utf8>)>>(
        "ffi_host_delete_var")
    .asFunction();

void Function(FFIHost, Pointer<Utf8>, int) ffiHostVarSetType = core
    .lookup<NativeFunction<Void Function(FFIHost, Pointer<Utf8>, Int32)>>(
        "ffi_host_var_set_type")
    .asFunction();

class VariablesWidget extends StatefulWidget {
  VariablesWidget(this.host);

  Host host;

  @override
  _VariablesWidget createState() => _VariablesWidget();
}

class _VariablesWidget extends State<VariablesWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Var>>(
      valueListenable: widget.host.vars,
      builder: (context, vars, w) {
        List<VarsGroup> groups = [];
        List<Var> ungroupedVars = [];

        for (var v in vars) {
          bool found = false;

          for (var group in groups) {
            if (group.name == v.group) {
              group.vars.add(v);
              found = true;
            }
          }

          if (!found) {
            groups.add(VarsGroup(v.group, widget.host, vars: [v]));
          }
        }

        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            color: Color.fromRGBO(40, 40, 40, 1.0)
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  "Variables",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w300
                  )
                )
              ),
            ] + groups + ungroupedVars + [
              Container(
                height: 16,
                alignment: Alignment.center,
                child: IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    print("Creating a group");
                  }
                )
              )
            ]
          )
        );
      }
    );
  }
}

class Var extends StatefulWidget {
  Var(this.host, {required this.index, required this.name, required this.group, required this.notifier});

  Host host;
  int index;
  String name;
  String group;
  ValueNotifier<dynamic> notifier;

  @override
  _Var createState() => _Var();
}

class _Var extends State<Var> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
        child: Container(
          width: null,
          height: 30,
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(80, 80, 80, 1.0),
            borderRadius: BorderRadius.circular(5)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              /*Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5)
                  ),
                ),
                child: VarTypeDropdown(0),
              ),*/
              VarTypeDropdown(widget, widget.host),
              const SizedBox(width: 10),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w300
                )
              ),
              const Expanded(
                child: SizedBox(),
              ),
              ValueListenableBuilder<dynamic>(
                valueListenable: widget.notifier,
                builder: (context, value, w) {
                  return Text(
                    value.toString().substring(0, min(value.toString().length, 8)),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w300
                    )
                  );
                }
              ),
              const SizedBox(width: 10),
              VarDeleteButton(
                onTap: () {
                  ffiHostDeleteVar(widget.host.host, widget.name.toNativeUtf8());
                  widget.host.refreshVariables();
                  widget.host.vars.notifyListeners();
                },
              )
            ]
          )
        )
      )
    );
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
      child: Column(
        children: [
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(60, 60, 60, 1.0),
              borderRadius: expanded ? const BorderRadius.vertical(top: Radius.circular(5)) : const BorderRadius.all(Radius.circular(5))
            ),
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
                  )
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 0, 10, 0),
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w300
                      ),
                    ),
                  )
                ),
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
                        ffiHostAddVar(widget.host.host, 0, widget.name.toNativeUtf8());
                        widget.host.refreshVariables();
                        widget.host.vars.notifyListeners();
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                ),
              ],
            )
          ),
          AnimatedSize(
            curve: Curves.fastLinearToSlowEaseIn,
            duration: const Duration(milliseconds: 500),
            child: Container(
              height: expanded ? null : 0,
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(60, 60, 60, 1.0),
                borderRadius: expanded ? const BorderRadius.vertical(bottom: Radius.circular(5)) : const BorderRadius.all(Radius.circular(5))
              ),
              child: Column(
                children: widget.vars
              ),
            )
          )
        ]
      )
    );
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
            color: hovering ? const Color.fromRGBO(100, 100, 100, 1.0) : Colors.red.withOpacity(0.0),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(5)
            )
          ),
        )
      )
    );
  }
}

class VarTypeDropdown extends StatefulWidget {
  VarTypeDropdown(this.v, this.host);

  Var v;
  Host host;

  @override
  State<VarTypeDropdown> createState() => _VarTypeDropdown();
}

class _VarTypeDropdown extends State<VarTypeDropdown> with TickerProviderStateMixin {

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

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

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
          color: color,
          borderRadius: BorderRadius.circular(5)
        ),
        child: GestureDetector(
          onTap: _toggleDropdown,
        )
      )
    );
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
              child: Stack(
                children: [
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
                              color: const Color.fromRGBO(120, 120, 120, 1.0),
                              borderRadius: BorderRadius.circular(5)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VarDropdownTypeElement(Icons.numbers, "Float", 0, Colors.green, widget.v),
                                VarDropdownTypeElement(Icons.select_all, "Boolean", 1, Colors.red, widget.v),
                              ]
                            )
                          )
                        )
                      )
                    )
                  )
                ]
              )
          )
        );
      }
    );
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
  VarDropdownTypeElement(this.iconData, this.text, this.type, this.color, this.v);

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
          var rawName = widget.v.name.toNativeUtf8();
          ffiHostVarSetType(widget.v.host.host, rawName, widget.type);
          calloc.free(rawName);
          widget.v.host.refreshVariables();
        },
        child: Container(
          height: 30,
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          color: hovering ? const Color.fromRGBO(140, 140, 140, 1.0) : const Color.fromRGBO(120, 120, 120, 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.all(Radius.circular(5))
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w300
                )
              )
            ]
          )
        )
      )
    );
  }
}
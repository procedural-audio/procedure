import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'dart:io';
import 'dart:ffi';

import '../host.dart';
import '../views/variables.dart';
import 'widget.dart';

Pointer<Utf8> Function(FFIWidgetPointer) ffiControlVariableGetName = core
    .lookup<NativeFunction<Pointer<Utf8> Function(FFIWidgetPointer)>>(
        "ffi_control_var_get_name")
    .asFunction();

void Function(FFIWidgetPointer, Pointer<Utf8>) ffiControlVariableSetName = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Pointer<Utf8>)>>(
        "ffi_control_var_set_name")
    .asFunction();

class ControlVariableWidget extends ModuleWidget {
  ControlVariableWidget(this.host, Host h, FFINode m, FFIWidget w)
      : super(h, m, w);

  Host host;

  @override
  Widget build(BuildContext context) {
    String? name;
    var nameRaw = ffiControlVariableGetName(widgetRaw.pointer);

    if (nameRaw != nullptr) {
      name = nameRaw.toDartString();
      calloc.free(nameRaw);
    }

    return VariableField(
      host: host,
      varName: name,
      onUpdate: (n) {
        setState(() {
          var nameRaw = n.toNativeUtf8();
          ffiControlVariableSetName(widgetRaw.pointer, nameRaw);
          calloc.free(nameRaw);
        });
      },
    );
  }
}

class VariableField extends StatefulWidget {
  VariableField(
      {required this.host, required this.varName, required this.onUpdate});

  Host host;
  String? varName;
  void Function(String) onUpdate;

  @override
  State<VariableField> createState() => _VariableField();
}

class _VariableField extends State<VariableField>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;

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
        child: Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
                color: const Color.fromRGBO(20, 20, 20, 1.0),
                borderRadius: BorderRadius.circular(5)),
            child: GestureDetector(
                onTap: _toggleDropdown,
                child: ValueListenableBuilder<List<Var>>(
                    valueListenable: widget.host.vars,
                    builder: (context, vars, w) {
                      bool found = false;

                      for (var v in vars) {
                        if (v.name == widget.varName) {
                          found = true;
                        }
                      }

                      return Center(
                          child: Text(
                              (found ? (widget.varName ?? "") : "(none)"),
                              style: const TextStyle(color: Colors.red)));
                    }))));
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
                                                50, 50, 50, 1.0),
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child:
                                            ValueListenableBuilder<List<Var>>(
                                          valueListenable: widget.host.vars,
                                          builder: (context, vars, w) {
                                            return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: vars.map((e) {
                                                  if (e.notifier.value
                                                      is double) {
                                                    return VariableFieldElement(
                                                        e.name, (s) {
                                                      widget.onUpdate(s);
                                                    });
                                                  } else {
                                                    return const SizedBox();
                                                  }
                                                }).toList());
                                          },
                                        ))))))
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

class VariableFieldElement extends StatefulWidget {
  VariableFieldElement(this.varName, this.onUpdate);

  String varName;
  void Function(String) onUpdate;

  @override
  State<VariableFieldElement> createState() => _VariableFieldElement();
}

class _VariableFieldElement extends State<VariableFieldElement> {
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
              widget.onUpdate(widget.varName);
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
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.varName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w300))
                    ]))));
  }
}

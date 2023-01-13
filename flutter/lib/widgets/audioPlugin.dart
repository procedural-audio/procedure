import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ffi';

import 'widget.dart';
import '../host.dart';

void Function(FFIWidgetPointer, int) ffiAudioPluginSetProcessAddr = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int64)>>(
        "ffi_audio_plugin_set_process_addr")
    .asFunction();

void Function(FFIWidgetPointer, int) ffiAudioPluginSetModuleId = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer, Int32)>>(
        "ffi_audio_plugin_set_module_id")
    .asFunction();

void Function(FFIWidgetPointer) ffiAudioPluginShowGui = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer)>>(
        "ffi_audio_plugin_show_gui")
    .asFunction();

class AudioPluginWidget extends ModuleWidget {
  AudioPluginWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w) {
    ffiAudioPluginSetModuleId(widgetRaw.pointer, api.ffiNodeGetId(moduleRaw));

    channel = const BasicMessageChannel("AudioPluginWidget", StringCodec());
    channel.setMessageHandler(handleMessages);
  }

  String? loadedPlugin;

  late BasicMessageChannel channel;

  Future<dynamic> handleMessages(dynamic message) async {
    if (message is String) {
      if (message == "show gui") {
        print("Showing GUI");
        ffiAudioPluginShowGui(widgetRaw.pointer);
      }
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30,
        decoration: BoxDecoration(
            color: const Color.fromRGBO(40, 40, 40, 1.0),
            border: Border.all(color: Colors.blue, width: 2.0),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Row(children: [
          GestureDetector(
              onTap: () {
                host.audioPlugins.showPlugin(api.ffiNodeGetId(moduleRaw));
              },
              child: Container(
                  width: 40,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: const Icon(
                    Icons.desktop_windows,
                    color: Colors.blue,
                    size: 14,
                  ))),
          ValueListenableBuilder<int?>(
              valueListenable: host.audioPlugins.processAddress,
              builder: (context, value, child) {
                if (value == null) {
                  ffiAudioPluginSetProcessAddr(widgetRaw.pointer, 0);
                } else {
                  ffiAudioPluginSetProcessAddr(widgetRaw.pointer, value);
                }

                return Container(
                  width: 1,
                  color: Colors.blue,
                );
              }),
          Expanded(
              child: ValueListenableBuilder<List<AudioPluginsCategory>>(
            valueListenable: host.audioPlugins.plugins,
            builder: (context, plugins, v) {
              return SearchableDropdown(
                value: loadedPlugin,
                elements: plugins,
                onSelect: (name) {
                  // print("Selected plugin " + value.toString());

                  if (name != null) {
                    host.audioPlugins
                        .createPlugin(api.ffiNodeGetId(moduleRaw), name);
                  } else {
                    print("Couldn't call createPlugin() for null name");
                  }
                },
              );
            },
          )),
        ]));
  }
}

class SearchableDropdown extends StatefulWidget {
  SearchableDropdown(
      {required this.value, required this.elements, required this.onSelect});

  String? value;
  List<AudioPluginsCategory> elements;
  void Function(String?) onSelect;

  @override
  State<SearchableDropdown> createState() => _SearchableDropdown();
}

class _SearchableDropdown extends State<SearchableDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;

  FocusNode textFieldFocus = FocusNode();

  TextEditingController controller = TextEditingController(text: "");

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 0));

    textFieldFocus.addListener(onTextFieldFocus);
  }

  void onTextFieldFocus() async {
    if (_isOpen) {
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

  @override
  void dispose() {
    _focusScopeNode.dispose();
    textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: const Color.fromRGBO(20, 20, 20, 1.0),
                borderRadius: BorderRadius.circular(5)),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      focusNode: textFieldFocus,
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) {
                        print("Search updated");
                      })),
              const SizedBox(
                width: 14,
                child: Icon(Icons.search,
                    color: Color.fromRGBO(60, 60, 60, 1.0), size: 16),
              )
            ])));
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
              autofocus: true,
              node: _focusScopeNode,
              child: GestureDetector(
                  onTap: () {
                    print("Unfocus");
                    textFieldFocus.unfocus();
                  },
                  behavior: HitTestBehavior.deferToChild,
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
                                  decoration: BoxDecoration(
                                      color:
                                          const Color.fromRGBO(20, 20, 20, 1.0),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: const Color.fromRGBO(
                                              40, 40, 40, 1.0),
                                          width: 1.0)),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: widget.elements.map((e) {
                                        return PluginListCategory(
                                          name: e.name,
                                          elements: e.plugins
                                              .map((e) => PluginListElement(
                                                  e, widget.onSelect))
                                              .toList(),
                                        );
                                      }).toList()),
                                ))))
                  ])));
        });
  }
}

class PluginListCategory extends StatefulWidget {
  final String name;
  final List<Widget> elements;

  PluginListCategory({required this.name, required this.elements});

  @override
  State<PluginListCategory> createState() => _PluginListCategory();
}

class _PluginListCategory extends State<PluginListCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 200,
        child: Column(
          children: <Widget>[
                MouseRegion(
                    onEnter: (event) {
                      print("Enter");
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
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print("Tapped");
                          setState(() {
                            expanded = !expanded;
                          });
                        },
                        onTapDown: (e) {
                          print("down");
                        },
                        onSecondaryTap: () {
                          print("Secondary tap");
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          height: 24,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(children: [
                              Icon(
                                expanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: const Color.fromRGBO(200, 200, 200, 1.0),
                                size: 20,
                              ),
                              Text(
                                widget.name,
                                style: const TextStyle(
                                    color: Color.fromRGBO(200, 200, 200, 1.0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300),
                              )
                            ]),
                          ),
                          decoration: BoxDecoration(
                            color: !hovering
                                ? const Color.fromRGBO(20, 20, 20, 1.0)
                                : const Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                        )))
              ] +
              (expanded ? widget.elements : []),
        ));
  }
}

class PluginListElement extends StatefulWidget {
  final String name;
  final void Function(String) onSelect;

  const PluginListElement(this.name, this.onSelect);

  @override
  State<PluginListElement> createState() => _PluginListElement();
}

class _PluginListElement extends State<PluginListElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    const Icon(
                      Icons.settings,
                      color: Colors.blue,
                      size: 16,
                    ),
                    Container(
                      width: 5,
                    ),
                    Text(
                      widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300),
                    ),
                  ])),
              decoration: BoxDecoration(
                color: !hovering
                    ? const Color.fromRGBO(20, 20, 20, 1.0)
                    : const Color.fromRGBO(40, 40, 40, 1.0),
              ),
            )));
  }
}

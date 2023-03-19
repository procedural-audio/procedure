import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:metasampler/widgets/browser.dart';
import 'package:metasampler/widgets/dynamicLine.dart';
import 'package:metasampler/widgets/iconButton.dart';
import 'package:metasampler/widgets/samplePicker.dart';

import 'dart:ui' as ui;
import 'dart:async';

import '../core.dart';
import '../module.dart';
import '../main.dart';

import '../views/variables.dart';
import 'knob.dart';
import 'nodeSequencer.dart';
import 'stack.dart';
import 'buttonSVG.dart';
import 'dropdown.dart';
import 'slider.dart';
import 'simpleButton.dart';
import 'simpleSwitch.dart';
import 'simplePad.dart';
import 'text.dart';
import 'pianoRoll.dart';
import 'envelope.dart';
import 'levelMeter.dart';
import 'stepSequencer.dart';
import 'keyboard.dart';
import 'sampler.dart';
import 'tabs.dart';
import 'refresh.dart';
import 'button.dart';
import 'grid.dart';
import 'fader.dart';
import 'input.dart';
import 'wavetable.dart';
import 'display.dart';
import 'buttonGrid.dart';
import 'searchableDropdown.dart';
import 'luaEditor.dart';
import 'painter.dart';
import 'mouseListener.dart';
import 'xyPad.dart';

ModuleWidget? createWidget(App app, RawNode moduleRaw, FFIWidget widgetRaw) {
  var nameRaw = ffiWidgetGetName(widgetRaw);
  var name = nameRaw.toDartString();
  calloc.free(nameRaw);

  print("Creating " + name);

  if (name == "Knob") {
    return KnobWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Stack") {
    return StackWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Row") {
    return RowWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Column") {
    return ColumnWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Transform") {
    return TransformWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Positioned") {
    return PositionedWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Padding") {
    return PaddingWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SizedBox") {
    return SizedBoxWidget(app, moduleRaw, widgetRaw);
  } else if (name == "IconButton") {
    return IconButtonWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SvgButton") {
    return ButtonSVG(app, moduleRaw, widgetRaw);
  } else if (name == "Svg") {
    return SvgWidget(app, moduleRaw, widgetRaw);
  } else if (name == "ButtonGrid") {
    return ButtonGridWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Dropdown") {
    return DropdownWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Slider") {
    return SliderWidget(app, moduleRaw, widgetRaw);
  } else if (name == "RangeSlider") {
    return RangeSliderWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SimpleButton") {
    return SimpleButtonWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SimpleSwitch") {
    return SimpleSwitchWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SimplePad") {
    return SimplePadWidget(app, moduleRaw, widgetRaw);
  } else if (name == "XYPad") {
    return XYPadWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Text") {
    return TextWidget(app, moduleRaw, widgetRaw);
  } else if (name == "NotesTrack") {
    return PianoRollWidget(app, moduleRaw, widgetRaw);
  } else if (name == "StepSequencer") {
    return StepSequencerWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Envelope") {
    return EnvelopeWidget(app, moduleRaw, widgetRaw);
  } else if (name == "LevelMeter") {
    return LevelMeterWidget(app, moduleRaw, widgetRaw);
  } else if (name == "MouseListener") {
    return MouseListenerWidget(app, moduleRaw, widgetRaw);
  } else if (name == "DynamicLine") {
    return DynamicLineWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Keyboard") {
    return KeyboardWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SampleMapper") {
    return SampleMapperWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SampleEditor") {
    return SampleEditorWidget(app, moduleRaw, widgetRaw);
  } else if (name == "LuaEditor") {
    return LuaEditorWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Tabs") {
    return TabsWidget(app, moduleRaw, widgetRaw);
  } else if (name == "NodeSequencer") {
    return NodeSequencerWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SamplePicker") {
    return SamplePickerWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Refresh") {
    return RefreshWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Rebuild") {
    return RebuildWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Button") {
    return ButtonWidget(app, moduleRaw, widgetRaw);
  } else if (name == "GridBuilder") {
    return GridBuilderWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Grid") {
    return GridWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Fader") {
    return FaderWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Input") {
    return InputWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Indicator") {
    return IndicatorWidget(app, moduleRaw, widgetRaw);
  } else if (name == "WavetablePicker") {
    return WavetableWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Display") {
    return DisplayWidget(app, moduleRaw, widgetRaw);
  } else if (name == "SearchableDropdown") {
    return SearchableDropdownWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Browser") {
    return BrowserWidget(app, moduleRaw, widgetRaw);
  } else if (name == "Painter") {
    return PainterWidget(app, moduleRaw, widgetRaw);
  } else if (name == "EmptyWidget") {
    return EmptyWidget(app, moduleRaw, widgetRaw);
  } else {
    print("Unknown widget " + name);
    return null;
  }
}

class EmptyWidget extends ModuleWidget {
  EmptyWidget(App a, RawNode m, FFIWidget w) : super(a, m, w);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

abstract class ModuleWidget extends StatefulWidget {
  final RawNode moduleRaw;
  final FFIWidget widgetRaw;
  final App app;

  late List<ModuleWidget> children = [];
  _ModuleWidgetState state = _ModuleWidgetState();

  ModuleWidget(this.app, this.moduleRaw, this.widgetRaw) {
    int childCount = ffiWidgetGetChildCount(widgetRaw);

    for (int i = 0; i < childCount; i++) {
      var childRaw = ffiWidgetGetChild(widgetRaw, i);
      ModuleWidget? widget = createWidget(app, moduleRaw, childRaw);

      if (widget != null) {
        children.add(widget);
      }
    }
  }

  ValueNotifier<Var?> assignedVar = ValueNotifier(null);

  Widget createEditor(BuildContext context) {
    return state.createEditor();
  }

  Widget build(BuildContext context);

  void setState(void Function() f) {
    if (state.mounted) {
      state.setState(f);
    }
  }

  void refresh() {
    state.refresh();
  }

  bool canAcceptVars() {
    return false;
  }

  bool willAcceptVar(Var v) {
    return false;
  }

  void onVarUpdate(dynamic value) {}

  void refreshRecursive() {
    state.refresh();
    for (var child in children) {
      child.refreshRecursive();
    }
  }

  void tick() {}

  void dispose() {}

  void initState() {}

  Future<ui.Image> loadImageFile(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> loadImageNetwork(String path) async {
    var completer = Completer<ImageInfo>();
    var img = NetworkImage(path);

    img
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      completer.complete(info);
    }));

    ImageInfo imageInfo = await completer.future;

    return imageInfo.image;
  }

  @override
  _ModuleWidgetState createState() {
    return state = _ModuleWidgetState();
  }
}

class _ModuleWidgetState extends State<ModuleWidget> {
  bool varDragging = false;
  bool labelHovering = false;

  @override
  void initState() {
    widget.initState();
    super.initState();
  }

  @override
  void dispose() {
    widget.dispose();
    super.dispose();
  }

  bool willAccept(Object? data) {
    return false;
  }

  void onVarUpdate() {
    if (widget.willAcceptVar(widget.assignedVar.value!)) {
      widget.onVarUpdate(widget.assignedVar.value!.notifier.value);
    } else {
      print("Type is incorrect");
    }
  }

  Widget createEditor() {
    return Container();
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var widgetTree = widget.build(context);

    if (widget.assignedVar.value != null) {
      widgetTree = Stack(children: [
        widgetTree,
        Align(
            alignment: Alignment.topLeft,
            child: MouseRegion(
                onEnter: (e) {
                  setState(() {
                    labelHovering = true;
                  });
                },
                onExit: (e) {
                  setState(() {
                    labelHovering = false;
                  });
                },
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: labelHovering ? 100 : 8,
                    height: labelHovering ? 14 : 8,
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                    decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: Visibility(
                        visible: labelHovering,
                        child: ValueListenableBuilder<String>(
                            valueListenable: widget.assignedVar.value!.name,
                            builder: (context, name, child) {
                              return Text(name,
                                  softWrap: false,
                                  style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 0.8),
                                      fontSize: 10));
                            })))))
      ]);
    }

    if (widget.canAcceptVars()) {
      return DragTarget(onWillAccept: (data) {
        setState(() {
          varDragging = true;
        });
        if (data != null) {
          if (data is Var) {
            return widget.willAcceptVar(data);
          } else {
            return false;
          }
        } else {
          return false;
        }
      }, onAccept: (v) {
        setState(() {
          varDragging = false;
        });

        if (widget.assignedVar.value != null) {
          widget.assignedVar.value!.notifier.removeListener(onVarUpdate);
          widget.assignedVar.value = v as Var;
          widget.assignedVar.value!.notifier.addListener(onVarUpdate);
          onVarUpdate();
        } else {
          widget.assignedVar.value = v as Var;
          widget.assignedVar.value!.notifier.addListener(onVarUpdate);
          onVarUpdate();
        }
      }, onLeave: (data) {
        if (varDragging) {
          setState(() {
            varDragging = false;
          });
        }
      }, builder: (context, candidateData, rejectedData) {
        if (varDragging) {
          bool shouldAccept = false;

          if (candidateData.isNotEmpty) {
            shouldAccept = widget.willAcceptVar(candidateData[0] as Var);
          }

          return Stack(
            children: [
              Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(30, 30, 30, 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Icon(
                      shouldAccept ? Icons.add : Icons.error,
                      color: shouldAccept ? Colors.green : Colors.red,
                    ),
                  ))
            ],
          );
        } else {
          return widgetTree;
        }
      });
    } else {
      return widgetTree;
    }
  }
}

/* Utilities */

Color intToColor(int value) {
  return Color(value);
}

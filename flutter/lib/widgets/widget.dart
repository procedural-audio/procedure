import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:metasampler/widgets/dynamicLine.dart';
import 'package:metasampler/widgets/samplePicker.dart';
import 'package:metasampler/widgets/textBox.dart';
import 'package:flutter/src/foundation/key.dart' as keyLib;
import 'package:spritewidget/spritewidget.dart';

import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import '../host.dart';

import 'knob.dart';
import 'nodeSequencer.dart';
import 'stack.dart';
import 'buttonSVG.dart';
import 'dropdown.dart';
import 'canvas.dart';
import 'simpleKnob.dart';
import 'slider.dart';
import 'simpleButton.dart';
import 'simpleSwitch.dart';
import 'simplePad.dart';
import 'imageFader.dart';
import 'imageKnob.dart';
import 'solidColor.dart';
import 'image.dart';
import 'text.dart';
import 'pianoRoll.dart';
import 'envelope.dart';
import 'levelMeter.dart';
import 'container.dart';
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
import 'audioPlugin.dart';

ModuleWidget? createWidget(Host host, FFINode moduleRaw, FFIWidget widgetRaw) {
  var nameRaw = api.ffiWidgetGetName(widgetRaw);
  var name = nameRaw.toDartString();
  calloc.free(nameRaw);

  print("Creating " + name);

  if (name == "Knob") {
    return KnobWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Stack") {
    return StackWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Positioned") {
    return PositionedWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Container") {
    return ContainerWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Padding") {
    return PaddingWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SizedBox") {
    return SizedBoxWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SvgButton") {
    return ButtonSVG(host, moduleRaw, widgetRaw);
  } else if (name == "Transform") {
    return TransformWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Svg") {
    return SvgWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Dropdown") {
    return DropdownWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Painter") {
    return CanvasWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SimpleKnob") {
    return SimpleKnobWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Slider") {
    return SliderWidget(host, moduleRaw, widgetRaw);
  } else if (name == "RangeSlider") {
    return RangeSliderWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SimpleButton") {
    return SimpleButtonWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SimpleSwitch") {
    return SimpleSwitchWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SimplePad") {
    return SimplePadWidget(host, moduleRaw, widgetRaw);
  } else if (name == "ImageFader") {
    return ImageFaderWidget(host, moduleRaw, widgetRaw);
  } else if (name == "ImageKnob") {
    return ImageKnobWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SolidColor") {
    return SolidColorWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Image") {
    return ImageWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Text") {
    return TextWidget(host, moduleRaw, widgetRaw);
  } else if (name == "NotesTrack") {
    return PianoRollWidget(host, moduleRaw, widgetRaw);
  } else if (name == "StepSequencer") {
    return StepSequencerWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Envelope") {
    return EnvelopeWidget(host, moduleRaw, widgetRaw);
  } else if (name == "LevelMeter") {
    return LevelMeterWidget(host, moduleRaw, widgetRaw);
  } else if (name == "DynamicLine") {
    return DynamicLineWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Keyboard") {
    return KeyboardWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SampleMapper") {
    return SampleMapperWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SampleEditor") {
    return SampleEditorWidget(host, moduleRaw, widgetRaw);
  } else if (name == "LuaEditor") {
    return LuaEditorWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Tabs") {
    return TabsWidget(host, moduleRaw, widgetRaw);
  } else if (name == "FloatBox") {
    return FloatBox(host, moduleRaw, widgetRaw);
  } else if (name == "NodeSequencer") {
    return NodeSequencerWidget(host, moduleRaw, widgetRaw);
  } else if (name == "SamplePicker") {
    return SamplePickerWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Refresh") {
    return RefreshWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Rebuild") {
    return RebuildWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Button") {
    return ButtonWidget(host, moduleRaw, widgetRaw);
  } else if (name == "GridBuilder") {
    return GridBuilderWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Grid") {
    return GridWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Fader") {
    return FaderWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Input") {
    return InputWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Indicator") {
    return IndicatorWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Wavetable") {
    return WavetableWidget(host, moduleRaw, widgetRaw);
  } else if (name == "Display") {
    return DisplayWidget(host, moduleRaw, widgetRaw);
  } else if (name == "AudioPlugin") {
    return AudioPluginWidget(host, moduleRaw, widgetRaw);
  } else if (name == "EmptyWidget") {
    //return EmptyWidget(moduleRaw, widgetRaw);
    return null;
  } else {
    print("Unknown widget " + name);
    return null;
  }
}

class EmptyWidget extends ModuleWidget {
  EmptyWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

abstract class ModuleWidget extends StatefulWidget {
  final FFINode moduleRaw;
  final FFIWidget widgetRaw;
  final Host host;

  late List<ModuleWidget> children = [];

  _ModuleWidgetState state = _ModuleWidgetState();

  ModuleWidget(this.host, this.moduleRaw, this.widgetRaw) {
    state.setBuildFunction(build);

    int childCount = api.ffiWidgetGetChildCount(widgetRaw);

    for (int i = 0; i < childCount; i++) {
      var childRaw = api.ffiWidgetGetChild(widgetRaw, i);
      ModuleWidget? widget = createWidget(host, moduleRaw, childRaw);

      if (widget != null) {
        children.add(widget);
      }
    }
  }

  Widget createEditor(BuildContext context) {
    return state.createEditor();
  }

  Widget build(BuildContext context);

  void setState(void Function() f) {
    state.setState(f);
  }

  void refresh() {
    state.refresh();
  }

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
    this.state = _ModuleWidgetState();
    this.state.setBuildFunction(build);
    return this.state;
  }
}

class _ModuleWidgetState extends State<ModuleWidget> {
  bool varDragging = false;

  // ignore: prefer_function_declarations_over_variables
  Widget Function(BuildContext) buildFunction = (b) {
    return const SizedBox(
      height: 14,
      child: Text(
        "Error: Wrong build method",
        style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            decoration: TextDecoration.none),
      ),
    );
  };

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

  _ModuleWidgetState();

  void setBuildFunction(Widget Function(BuildContext) f) {
    buildFunction = f;
  }

  bool willAccept(Object? data) {
    return false;
  }

  Widget createEditor() {
    return Container();
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return buildFunction(context);
  }
}

/* Utilities */

Color intToColor(int value) {
  return Color(value);
}

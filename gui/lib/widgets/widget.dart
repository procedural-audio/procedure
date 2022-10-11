import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:metasampler/widgets/dynamicLine.dart';
import 'package:metasampler/widgets/samplePicker.dart';
import 'package:metasampler/widgets/textBox.dart';
import 'package:flutter/src/foundation/key.dart' as keyLib;

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
import 'controlVariable.dart';
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
  } else if (name == "ControlVariable") {
    return ControlVariableWidget(host, host, moduleRaw, widgetRaw);
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

class PathSegmentAction {
  int kind = 0;
  double f1 = 0.0;
  double f2 = 0.0;
  double f3 = 0.0;
  double f4 = 0.0;
  double f5 = 0.0;
  double f6 = 0.0;

  PathSegmentAction(
      {this.kind = 0,
      this.f1 = 0,
      this.f2 = 0,
      this.f3 = 0,
      this.f4 = 0,
      this.f5 = 0,
      this.f6 = 0});
}

class PaintAction {
  int kind = 0;
  int i1 = 0;
  int i2 = 0;
  int i3 = 0;
  int i4 = 0;
  double f1 = 0.0;
  double f2 = 0.0;
  int width = 0;
  Color color = Colors.blue;
  int glow = 0;
  List<PathSegmentAction> segments = [];

  PaintAction(
      {this.kind = 0,
      this.i1 = 0,
      this.i2 = 0,
      this.i3 = 0,
      this.i4 = 0,
      this.f1 = 0,
      this.f2 = 0,
      this.color = Colors.blue,
      this.width = 5,
      this.glow = 0,
      required this.segments});
}

class ModuleWidgetPainter extends CustomPainter {
  final List<PaintAction> paintActions;

  ModuleWidgetPainter({required this.paintActions});

  @override
  void paint(Canvas canvas, Size size) {
    for (var action in paintActions) {
      Paint paint = Paint();
      paint.color = action.color;
      paint.strokeWidth = action.width.toDouble();
      paint.style = PaintingStyle.stroke;

      if (action.kind == 1) {
        canvas.drawArc(
            Rect.fromLTWH(action.i1.toDouble(), action.i2.toDouble(),
                action.i3.toDouble(), action.i4.toDouble()),
            action.f1,
            action.f2,
            true,
            paint);
      } else if (action.kind == 2) {
        canvas.drawCircle(Offset(action.i1.toDouble(), action.i2.toDouble()),
            action.f1, paint);
      } else if (action.kind == 3) {
        canvas.drawRect(
            Rect.fromLTWH(action.i1.toDouble(), action.i2.toDouble(),
                action.i3.toDouble(), action.i4.toDouble()),
            paint);
      } else if (action.kind == 4) {
        canvas.drawRRect(
            RRect.fromLTRBR(
                action.i1.toDouble(),
                action.i2.toDouble(),
                action.i3.toDouble(),
                action.i4.toDouble(),
                Radius.circular(action.f1)),
            paint);
      } else if (action.kind == 5) {
        canvas.drawLine(Offset(action.i1.toDouble(), action.i2.toDouble()),
            Offset(action.i3.toDouble(), action.i4.toDouble()), paint);
      } else if (action.kind == 6) {
        // Draw point
      } else if (action.kind == 7) {
        // Draw points
      } else if (action.kind == 8) {
        Path path = Path();

        for (var segment in action.segments) {
          if (segment.kind == 1) {
            path.moveTo(segment.f1, segment.f2);
          } else if (segment.kind == 2) {
            path.lineTo(segment.f1, segment.f2);
          } else if (segment.kind == 3) {
            path.cubicTo(segment.f1, segment.f2, segment.f3, segment.f4,
                segment.f5, segment.f6);
          } else if (segment.kind == 4) {
            path.arcTo(
                Rect.fromLTWH(segment.f1, segment.f2, segment.f3, segment.f4),
                segment.f5,
                segment.f6,
                true);
          } else if (segment.kind == 5) {
            path.conicTo(
                segment.f1, segment.f2, segment.f3, segment.f4, segment.f5);
          } else if (segment.kind == 6) {
            path.quadraticBezierTo(
                segment.f1, segment.f2, segment.f3, segment.f4);
          }
        }

        canvas.drawPath(path, paint);
      } else if (action.kind == 9) {
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      } else if (action.kind == 10) {
        // Draw image
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Color intToColor(int value) {
  return Color(value);
}

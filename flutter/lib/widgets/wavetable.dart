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

/*double Function(RawWidgetPointer) ffiFaderGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
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

class WavetableWidget extends ModuleWidget {
  WavetableWidget(Node n, RawNode m, RawWidget w) : super(n, m, w);

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

      categoryWidgets.add(
        Padding(
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
              child: Row(
                children: [
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
                ],
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? Colors.grey : Colors.grey.withAlpha(100),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> elementWidgets = [];

    for (String element in presets[selectedCategory]) {
      elementWidgets.add(
        GestureDetector(
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
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );

      elementWidgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Container(
            color: Colors.grey,
            height: 0.5,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Visibility(
              visible: showPresets,
              child: Row(
                children: [
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
                ],
              ),
            ),
            Visibility(
              visible: !showPresets,
              child: CustomPaint(
                painter: WavetablePainter(wavetable),
              ),
            ),
          ],
        ),
      ),
    );
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

      List<Offset> points = [
        Offset(0.0 + offsetX, offsetY),
      ];

      int j = 0;

      for (var w in wave) {
        var curr = Offset(
          width / wave.length * j + offsetX,
          height / 2 * w + offsetY,
        );

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

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metasampler/host.dart';
import 'package:statsfl/statsfl.dart';

import 'views/info.dart';
import 'views/settings.dart';
import 'views/browser.dart';
import 'views/samples.dart';
import 'views/presets.dart';
import 'views/right_click.dart';
import 'views/bar.dart';

import 'views/variables.dart';
import 'widgets/widget.dart';
import 'instrument.dart';
import 'module.dart';

import 'config.dart';

import 'dart:ffi' as ffi;

import 'ui/layout.dart';

class Globals {
  ValueNotifier<String> pinLabel = ValueNotifier("");
  Offset labelPosition = const Offset(0.0, 0.0);

  /* Instruments */

  InstrumentInfo instrument = InstrumentInfo("Untitled Instrument",
      "/home/chase/github/metasampler/content/instruments/Untitled Instrument");

  PresetInfo preset = PresetInfo(
      "Untitled Instrument",
      File(
          "/home/chase/github/metasampler/content/instruments/Untitled Instrument"));

  ValueNotifier<List<InstrumentInfo>> instruments = ValueNotifier([]);

  List<InstrumentInfo> instruments2 = [];
  InstrumentInfo browserInstrument = InstrumentInfo("Untitled Instrument",
      "/home/chase/github/metasampler/content/instruments/Untitled Instrument");

  ValueNotifier<Widget?> selectedWidgetEditor = ValueNotifier(null);

  /* Patching View */

  double zoom = 1.0;
  TempConnector? tempConnector;
  int selectedModule = -1;

  bool patchingScaleEnabled = true;

  Settings settings = Settings();

  RootWidget? rootWidget;
}

void callTickRecursive(ModuleWidget widget) {
  widget.tick();

  for (var child in widget.children) {
    callTickRecursive(child);
  }
}

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  print("Found " + args.length.toString() + " args in main()");

  if (args.isEmpty) {
    print("Failed to get host pointer");

    Host core = Host(api.ffiCreateHost());

    core.graph.refresh();

    var json = jsonDecode(
        File(contentPath + "/instruments/UntitledInstrument/info/info.json")
            .readAsStringSync());

    core.globals.instrument = InstrumentInfo.fromJson(
        json, contentPath + "/instruments/UntitledInstrument");

    runApp(Window(core));
  } else {
    var hostAddr = int.parse(args[0].split(": ").last);

    Host core = Host(api.ffiHackConvert(hostAddr));

    core.graph.refresh();

    /*var json = jsonDecode(
        File(contentPath + "/instruments/UntitledInstrument/info/info.json")
            .readAsStringSync());

    core.globals.instrument = InstrumentInfo.fromJson(
        json, contentPath + "/instruments/UntitledInstrument");*/

    runApp(Window(core));
  }
}

/* ========== Main Code ========== */

class Window extends StatefulWidget {
  Window(this.host) {
    instrumentView = InstrumentView(host);
  }

  Host host;
  late InstrumentView instrumentView;

  ValueNotifier<bool> instViewVisible = ValueNotifier(true);

  @override
  State<Window> createState() => _Window();
}

class _Window extends State<Window> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          splashColor: const Color.fromRGBO(20, 20, 20, 1.0),
        ),
        home: Scaffold(
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
            body: Stack(children: [
              Stack(children: <Widget>[
                Container(
                    color: const Color.fromRGBO(10, 10, 10, 1.0),
                    child: Stack(children: [
                      ValueListenableBuilder<bool>(
                          valueListenable: widget.instViewVisible,
                          builder: (context, visible, w) {
                            return Visibility(
                              child: widget.instrumentView,
                              visible: visible,
                              maintainState: true,
                            );
                          }),
                      ValueListenableBuilder<bool>(
                          valueListenable: widget.instViewVisible,
                          builder: (context, visible, w) {
                            return Visibility(
                              child: PatchingView(widget.host),
                              visible: !visible,
                              maintainState: true,
                            );
                          }),
                      Bar(widget, widget.host)
                    ]))
              ])
            ])));
  }
}

class PatchingView extends StatefulWidget {
  PatchingView(this.host);

  Host host;

  @override
  State<PatchingView> createState() => _PatchingView();
}

class _PatchingView extends State<PatchingView> {
  late Grid grid;

  var mouseOffset = const Offset(0, 0);
  var righttClickOffset = const Offset(0, 0);
  var rightClickVisible = false;
  var moduleMenuVisible = false;

  var wheelVisible = false;
  List<String> wheelModules = [];

  FocusNode focusNode = FocusNode();

  TransformationController controller = TransformationController();

  @override
  void initState() {
    grid = Grid(widget.host);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);

    return RawKeyboardListener(
        focusNode: focusNode,
        onKey: (event) {
          if (rightClickVisible) {
            return;
          }

          if (event.data.physicalKey == PhysicalKeyboardKey.keyS) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = ["Sampler", "Simpler", "Granular", "Looper"];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          } else if (event.data.physicalKey == PhysicalKeyboardKey.keyO) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = [
                  "Digital",
                  "Analog",
                  "Noise",
                  "Wavetable",
                  "Additive",
                  "Polygon"
                ];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          } else if (event.data.physicalKey == PhysicalKeyboardKey.keyF) {
            if (event.runtimeType == RawKeyDownEvent) {
              setState(() {
                wheelVisible = true;
                wheelModules = ["Sampler", "Analog Osc"];
              });
            } else {
              setState(() {
                wheelVisible = false;
              });
            }
          }
        },
        child: Stack(fit: StackFit.loose, children: [
          InteractiveViewer(
            transformationController: controller,
            child: grid,
            minScale: 0.1,
            maxScale: 1.5,
            panEnabled: true,
            scaleEnabled: widget.host.globals.patchingScaleEnabled,
            clipBehavior: Clip.none,
            constrained: false,
            onInteractionUpdate: (details) {
              widget.host.globals.zoom *= details.scale;
              if (widget.host.globals.zoom < 0.1) {
                widget.host.globals.zoom = 0.1;
              } else if (widget.host.globals.zoom > 1.5) {
                widget.host.globals.zoom = 1.5;
              }
            },
          ),
          GestureDetector(
              // Right click menu region
              behavior: HitTestBehavior.translucent,
              onSecondaryTap: () {
                print("Secondary tap right-click menu");

                if (widget.host.globals.selectedModule == -1) {
                  righttClickOffset = mouseOffset;
                  setState(() {
                    rightClickVisible = true;
                  });
                } else {
                  righttClickOffset = mouseOffset;
                  setState(() {
                    moduleMenuVisible = true;
                  });
                }
              }),
          Visibility(
            // Right click menu
            visible: rightClickVisible,
            child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: RightClickView(
                  widget.host,
                  addPosition: Offset(
                      righttClickOffset.dx -
                          controller.value.getTranslation().x,
                      righttClickOffset.dy -
                          controller.value.getTranslation().y),
                )),
          ),
          Visibility(
            // Right click menu
            visible: moduleMenuVisible,
            child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: ModuleMenu()),
          ),
          Listener(
            // Hide right-click menu
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (rightClickVisible &&
                  widget.host.globals.patchingScaleEnabled) {
                setState(() {
                  rightClickVisible = false;
                });
              } else if (moduleMenuVisible &&
                  widget.host.globals.patchingScaleEnabled) {
                setState(() {
                  moduleMenuVisible = false;
                });
              }
            },
          ),
          Visibility(
            // Module wheel
            visible: wheelVisible,
            child: Positioned(
                left: mouseOffset.dx - 150,
                top: mouseOffset.dy - 100,
                child: ModuleWheel(wheelModules)),
          ),
          MouseRegion(
            opaque: false,
            onHover: (event) {
              mouseOffset = event.localPosition;
              // print(mouseOffset.toString());
            },
          ),
          ValueListenableBuilder<String>(
              valueListenable: widget.host.globals.pinLabel,
              builder: (context, value, w) {
                return Visibility(
                    visible: value != "",
                    child: Positioned(
                      left: widget.host.globals.labelPosition.dx,
                      top: widget.host.globals.labelPosition.dy,
                      child: PinLabel(value),
                    ));
              })
        ]));
  }
}

class ModuleMenu extends StatefulWidget {
  @override
  _ModuleMenu createState() => _ModuleMenu();
}

class _ModuleMenu extends State<ModuleMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
          color: MyTheme.grey20, border: Border.all(color: MyTheme.grey40)),
      child: Column(
        children: [
          ModuleMenuItem(
            text: "Presets",
            iconData: Icons.view_agenda,
            onTap: () {
              print("Tapped item");
            },
          ),
          ModuleMenuItem(
            text: "Tutorial",
            iconData: Icons.description,
            onTap: () {
              print("Tapped item");
            },
          ),
          ModuleMenuItem(
            text: "Duplicate",
            iconData: Icons.copy,
            onTap: () {
              print("Tapped item");
            },
          ),
          ModuleMenuItem(
            text: "Delete",
            iconData: Icons.delete,
            onTap: () {
              print("Tapped item");
            },
          ),
          const SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }
}

class ModuleMenuItem extends StatefulWidget {
  ModuleMenuItem(
      {required this.text, required this.iconData, required this.onTap});

  String text;
  IconData iconData;
  void Function() onTap;

  @override
  _ModuleMenuItem createState() => _ModuleMenuItem();
}

class _ModuleMenuItem extends State<ModuleMenuItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30,
        decoration: BoxDecoration(
          color: MyTheme.grey20,
        ),
        child: GestureDetector(
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(
                  widget.iconData,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w300),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}

class ModuleWheel extends StatefulWidget {
  ModuleWheel(this.modules);

  List<String> modules;

  @override
  _ModuleWheel createState() => _ModuleWheel();
}

class _ModuleWheel extends State<ModuleWheel> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    const double width = 300;
    const double height = 200;
    const double elementWidth = 80;
    const double elementHeight = 32;

    const double radius = 80;
    double gap = 2 * pi / widget.modules.length;
    double angle = 0.0;

    for (var module in widget.modules) {
      double x = sin(angle) * radius - (elementWidth / 2);
      double y = cos(angle) * radius - (elementHeight / 2);

      children.add(Positioned(
        left: x + width / 2,
        top: y + height / 2,
        child: Container(
          width: elementWidth,
          height: elementHeight,
          alignment: Alignment.center,
          child: Text(module,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(60, 60, 60, 0.5),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
      ));

      angle += gap;
    }

    return Container(
      width: width,
      height: height,
      //color: const Color.fromRGBO(40, 40, 40, 0.5),
      child: Stack(
        children: children +
            [
              Positioned(
                left: width / 2 - 8,
                top: height / 2 - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(100, 100, 100, 0.5),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                          color: const Color.fromRGBO(200, 200, 200, 0.5),
                          width: 2.0)),
                ),
              )
            ],
      ),
    );
  }
}

_GridState? gGridState;

class Grid extends StatefulWidget {
  Grid(this.host);

  Host host;

  @override
  _GridState createState() => _GridState();
}

class _GridState extends State<Grid> {
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    gGridState = this; // SHOUD MOVE THIS TO CONSTRUCTOR ???

    return Container(
      width: 40000,
      height: 20000,
      child: CustomPaint(
        size: const Size(40000, 20000),
        painter: GridPainter(),
        child: Stack(
          children: [
            TempConnectorWidget(widget.host),
            Connectors(widget.host),
            Stack(
              children: widget.host.graph.modules,
            ),
            DragTarget(
              builder: (BuildContext context, List<dynamic> accepted,
                  List<dynamic> rejected) {
                return Container(
                  width: 40000,
                  height: 20000,
                  child: GestureDetector(
                    // THIS DOESN'T WORK
                    behavior: HitTestBehavior.deferToChild,
                    onTap: () {
                      print("TODO: Fixup tap");
                      /*var oldWidget = widget.host.globals.selectedModule;
                      widget.host.globals.selectedModule = -1;
                      for (var widget in widget.host.graph.moduleWidgets) {
                        if (widget.module.id == oldWidget) {
                          widget.refresh();
                        }
                      }
                      */
                    },
                  ),
                );
              },
              onAccept: (int data) {},
              onWillAccept: (int? data) {
                return true;
              },
            ),
            // globals.pinLabel,
          ],
        ),
      ),
    );
  }
}

class TempConnector {
  int moduleId = 0;
  int pinIndex = 0;
  double endX = 0;
  double endY = 0;
  IO type = IO.audio;

  int hoveringId = -1;
  int hoveringIndex = -1;
}

_TempConnectorState? gTempConnectorState;

class TempConnectorWidget extends StatefulWidget {
  TempConnectorWidget(this.host);

  Host host;

  @override
  _TempConnectorState createState() => _TempConnectorState();
}

class _TempConnectorState extends State<TempConnectorWidget> {
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    gTempConnectorState = this;

    return CustomPaint(
      size: const Size(4000, 2000),
      painter: TempConnectorPainter(widget.host),
    );
  }
}

class TempConnectorPainter extends CustomPainter {
  TempConnectorPainter(this.host);

  Host host;

  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()
      ..style = PaintingStyle.stroke
      ..color = MyTheme.audio
      ..strokeWidth = 4;
    final paintRed = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 4;
    final paintGreen = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.green
      ..strokeWidth = 4;
    final paintPurple = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 4;

    var connector = host.globals.tempConnector ?? TempConnector();

    if (host.globals.tempConnector == null) {
      return;
    }

    for (var module1 in host.graph.modules) {
      if (connector.moduleId == module1.id) {
        var pin1 = module1.pins[connector.pinIndex];

        double startx = module1.position.dx + pin1.offset.dx;
        double starty = module1.position.dy + pin1.offset.dy;

        double endx = connector.endX + startx;
        double endy = connector.endY + starty;

        var path = Path()
          ..moveTo(startx + 7, starty + 7)
          ..lineTo(startx + (endx - startx) / 6 * 1, starty + 7)
          ..lineTo(startx + (endx - startx) / 6 * 2, (starty + endy) / 2)
          ..lineTo(startx + (endx - startx) / 6 * 4, (starty + endy) / 2)
          ..lineTo(startx + (endx - startx) / 6 * 5, endy + 7)
          ..lineTo(endx + 7, endy + 7);

        var width = (endx - startx);
        var height = (endy - starty);

        startx += 7;
        endx += 7;
        starty += 7;
        endy += 7;

        var distance = sqrt(pow(endx - startx, 2) + pow(endy - starty, 2));
        var delta = 5 + distance / 4;

        if (delta > 150) {
          delta = 150;
        }

        path = Path()
          ..moveTo(startx, starty)
          ..cubicTo(startx + delta, starty, startx + width / 2,
              starty + height / 2, startx + width / 2, starty + height / 2)
          ..cubicTo(startx + width / 2, starty + height / 2, endx - delta, endy,
              endx, endy);

        //canvas.drawShadow(path, MyTheme.audio, 2.0, false);

        if (connector.type == IO.audio) {
          canvas.drawPath(path, paintBlue);
        } else if (connector.type == IO.midi) {
          canvas.drawPath(path, paintGreen);
        } else if (connector.type == IO.control) {
          canvas.drawPath(path, paintRed);
        } else if (connector.type == IO.time) {
          canvas.drawPath(path, paintPurple);
        }

        break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

_ConnectorsState? gConnectorsState;

class Connectors extends StatefulWidget {
  Connectors(this.host);

  Host host;

  @override
  _ConnectorsState createState() => _ConnectorsState();
}

class _ConnectorsState extends State<Connectors> {
  void refreshConnectors() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    gConnectorsState = this;

    return CustomPaint(
      size: const Size(4000, 2000),
      painter: ConnectorsPainter(widget.host),
    );
  }
}

class ConnectorsPainter extends CustomPainter {
  ConnectorsPainter(this.host);

  Host host;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue
      ..strokeWidth = 4;

    for (var connector in host.graph.connectors) {
      for (var module1 in host.graph.modules) {
        if (connector.start.moduleId == module1.id) {
          for (var module2 in host.graph.modules) {
            if (connector.end.moduleId == module2.id) {
              var pin1 = module1.pins[connector.start.index];
              var pin2 = module2.pins[connector.end.index];

              double startx = module1.position.dx + pin1.offset.dx;
              double starty = module1.position.dy + pin1.offset.dy;

              double endx = module2.position.dx + pin2.offset.dx;
              double endy = module2.position.dy + pin2.offset.dy;

              var path = Path()
                ..moveTo(startx + 7, starty + 7)
                ..lineTo(startx + (endx - startx) / 6 * 1, starty + 7)
                ..lineTo(startx + (endx - startx) / 6 * 2, (starty + endy) / 2)
                ..lineTo(startx + (endx - startx) / 6 * 4, (starty + endy) / 2)
                ..lineTo(startx + (endx - startx) / 6 * 5, endy + 7)
                ..lineTo(endx + 7, endy + 7);

              var width = (endx - startx);
              var height = (endy - starty);

              startx += 7;
              endx += 7;
              starty += 7;
              endy += 7;

              var distance =
                  sqrt(pow(endx - startx, 2) + pow(endy - starty, 2));
              var delta = 5 + distance / 4;

              if (delta > 150) {
                delta = 150;
              }

              path = Path()
                ..moveTo(startx, starty)
                ..cubicTo(
                    startx + delta,
                    starty,
                    startx + width / 2,
                    starty + height / 2,
                    startx + width / 2,
                    starty + height / 2)
                ..cubicTo(startx + width / 2, starty + height / 2, endx - delta,
                    endy, endx, endy);

              //canvas.drawShadow(path, MyTheme.audio, 2.0, false);

              bool selected = module1.id == host.globals.selectedModule ||
                  module2.id == host.globals.selectedModule;

              if (connector.type == IO.audio) {
                if (selected) {
                  paint.color = Colors.blue;
                } else {
                  paint.color = Colors.blue.withOpacity(0.3);
                }

                canvas.drawPath(path, paint);
              } else if (connector.type == IO.midi) {
                if (selected) {
                  paint.color = Colors.green;
                } else {
                  paint.color = Colors.green.withOpacity(0.3);
                }

                canvas.drawPath(path, paint);
              } else if (connector.type == IO.control) {
                if (selected) {
                  paint.color = Colors.red;
                } else {
                  paint.color = Colors.red.withOpacity(0.3);
                }

                canvas.drawPath(path, paint);
              } else if (connector.type == IO.time) {
                if (selected) {
                  paint.color = Colors.deepPurpleAccent;
                } else {
                  paint.color = Colors.deepPurpleAccent.withOpacity(0.3);
                }

                canvas.drawPath(path, paint);
              }

              break;
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 25;
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += spacing) {
      final p1 = Offset(i, 0);
      final p2 = Offset(i, size.height);

      canvas.drawLine(p1, p2, paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      final p1 = Offset(0, i);
      final p2 = Offset(size.width, i);

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:metasampler/host.dart';
import 'package:metasampler/ui/code_editor/code_text_field.dart';

import 'views/info.dart';
import 'views/settings.dart';
import 'views/presets.dart';
import 'views/right_click.dart';
import 'views/bar.dart';

import 'instrument.dart';
import 'module.dart';

import 'widgets/widget.dart';
import 'ui/layout.dart';
import 'core.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isEmpty) {
    runApp(
      App(
        core: Core.create(),
        assets: Assets.platformDefault(),
      ),
    );
  } else {
    var addr = int.parse(args[0].split(": ").last);

    runApp(
      App(
        core: Core.from(addr),
        assets: Assets.platformDefault(),
      ),
    );
  }
}

class Project {
  Project({
    required this.app,
    required this.info,
    required this.patch,
  });

  static Project untitled(App app) {
    return Project(
      app: app,
      info: ProjectInfo.loadSync(
        "/Users/chasekanipe/Github/assets/projects/UntitledInstrument",
      ),
      patch: ValueNotifier(
        Patch(app),
      ),
    );
  }

  final ProjectInfo info;
  final ValueNotifier<Patch> patch;
  final App app;

  bool rename(String name) {
    print("Project rename not implemented");

    if (!app.assets.projects.contains(name)) {
      info.name.value = name;
      return true;
    } else {
      return false;
    }
  }

  // ValueNotifier<PresetInfo> preset;
  // ValueNotifier<Graph> graph;
}

class App extends StatefulWidget {
  App({required this.core, required this.assets}) {
    project = ValueNotifier(Project.untitled(this));
  }

  Core core;
  Assets assets;

  late ValueNotifier<Project> project;

  // ======= Other stuff =======

  ValueNotifier<int> selectedModule = ValueNotifier(-1);
  ValueNotifier<List<ModuleSpec>> moduleSpecs = ValueNotifier([]);

  var loadedPreset = ValueNotifier(PresetInfo("", File("")));

  ValueNotifier<List<PresetInfo>> presets = ValueNotifier([]);

  RootWidget? rootWidget;
  bool patchingScaleEnabled = true;

  double zoom = 1.0;
  TempConnector? tempConnector;

  ValueNotifier<String> pinLabel = ValueNotifier("");
  Offset labelPosition = const Offset(0.0, 0.0);

  @override
  State<App> createState() => _App();
}

class _App extends State<App> {
  bool instViewVisible = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(splashColor: const Color.fromRGBO(20, 20, 20, 1.0)),
      home: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        body: Stack(
          children: <Widget>[
            Container(
              color: const Color.fromRGBO(10, 10, 10, 1.0),
              child: Stack(
                children: [
                  Visibility(
                    child: InstrumentView(widget),
                    visible: instViewVisible,
                    maintainState: true,
                  ),
                  Visibility(
                    child: PatchingView(widget),
                    visible: !instViewVisible,
                    maintainState: true,
                  ),
                  Bar(
                    app: widget,
                    instViewVisible: instViewVisible,
                    onViewSwitch: () {
                      setState(() {
                        instViewVisible = !instViewVisible;
                      });
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void callTickRecursive(ModuleWidget widget) {
  widget.tick();

  for (var child in widget.children) {
    callTickRecursive(child);
  }
}

class PatchingView extends StatefulWidget {
  PatchingView(this.app);

  App app;

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

  double zoom = 1.0;

  @override
  void initState() {
    grid = Grid(widget.app);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);

    return RawKeyboardListener(
      focusNode: focusNode,
      /*onKey: (event) {
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
        },*/
      child: ClipRect(
        child: Stack(
          fit: StackFit.loose,
          children: [
            InteractiveViewer(
              transformationController: controller,
              child: grid,
              minScale: 0.1,
              maxScale: 1.5,
              panEnabled: true,
              scaleEnabled: true, // widget.app.patchingScaleEnabled,
              clipBehavior: Clip.none,
              constrained: false,
              onInteractionUpdate: (details) {
                setState(() {
                  zoom *= details.scale;
                  if (zoom < 0.1) {
                    zoom = 0.1;
                  } else if (zoom > 1.5) {
                    zoom = 1.5;
                  }
                });
              },
            ),
            GestureDetector(
              // Right click menu region
              behavior: HitTestBehavior.translucent,
              onSecondaryTap: () {
                print("Secondary tap right-click menu");

                if (widget.app.selectedModule.value == -1) {
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
              },
            ),
            Visibility(
              // Right click menu
              visible: rightClickVisible,
              child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: RightClickView(
                  widget.app,
                  specs: widget.app.moduleSpecs,
                  addPosition: Offset(
                      righttClickOffset.dx -
                          controller.value.getTranslation().x,
                      righttClickOffset.dy -
                          controller.value.getTranslation().y),
                ),
              ),
            ),
            Visibility(
              // Right click menu
              visible: moduleMenuVisible,
              child: Positioned(
                left: righttClickOffset.dx,
                top: righttClickOffset.dy,
                child: ModuleMenu(),
              ),
            ),
            Listener(
              // Hide right-click menu
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (rightClickVisible && widget.app.patchingScaleEnabled) {
                  setState(() {
                    rightClickVisible = false;
                  });
                } else if (moduleMenuVisible &&
                    widget.app.patchingScaleEnabled) {
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
                child: ModuleWheel(wheelModules),
              ),
            ),
            MouseRegion(
              opaque: false,
              onHover: (event) {
                mouseOffset = event.localPosition;
                // print(mouseOffset.toString());
              },
            ),
            ValueListenableBuilder<String>(
              valueListenable: widget.app.pinLabel,
              builder: (context, value, w) {
                return Visibility(
                    visible: value != "",
                    child: Positioned(
                      left: widget.app.labelPosition.dx,
                      top: widget.app.labelPosition.dy,
                      child: PinLabel(value),
                    ));
              },
            ),
            // Positioned(top: 0, bottom: 0, right: 0, child: CodeEditor())
          ],
        ),
      ),
    );
  }
}

class CodeEditor extends StatefulWidget {
  @override
  _CodeEditor createState() => _CodeEditor();
}

class _CodeEditor extends State<CodeEditor> {
  final codeController = CodeController(modifiers: [
    const IndentModifier(handleBrackets: true)
  ], stringMap: const {
    'function': TextStyle(color: Color(0xfffb7b72)),
    'if': TextStyle(color: Color(0xfffb7b72)),
    'then': TextStyle(color: Color(0xfffb7b72)),
    'else': TextStyle(color: Color(0xfffb7b72)),
    'end': TextStyle(color: Color(0xfffb7b72)),
    'return': TextStyle(color: Color(0xfffb7b72)),
    'print': TextStyle(color: Color(0xff74b8f4)),
    '"': TextStyle(color: Color(0xffa5d6ff)),
  }, text: """function fact (n)
      if n == 0 then
        return 1
      else
        return n * fact(n-1)
      end
    end
    
    print("enter a number:")
    a = io.read("*number")        -- read a number
    print(fact(a))""");

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(children: [
        Container(
            width: 400,
            height: 30,
            decoration: const BoxDecoration(color: Colors.grey)),
        Container(
            width: 400,
            height: constraints.maxHeight - 30,
            child: CodeField(
                isDense: true,
                controller: codeController,
                lineNumberStyle: const LineNumberStyle(
                    width: 30,
                    textStyle: TextStyle(
                        color: Color.fromRGBO(100, 100, 100, 1.0),
                        fontSize: 10)),
                textStyle:
                    const TextStyle(fontSize: 14, color: Color(0xffc9d1d9))))
      ]);
    });
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
  Grid(this.app);

  App app;

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
        size: const ui.Size(40000, 20000),
        painter: GridPainter(),
        child: Stack(
          children: [
            TempConnectorWidget(widget.app),
            Connectors(widget.app),
            Stack(
              children: widget.app.project.value.patch.value.modules,
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
                      /*var oldWidget = widget.app.selectedModule;
                      widget.app.selectedModule = -1;
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
  TempConnectorWidget(this.app);

  App app;

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
      size: const ui.Size(4000, 2000),
      painter: TempConnectorPainter(widget.app),
    );
  }
}

class TempConnectorPainter extends CustomPainter {
  TempConnectorPainter(this.app);

  App app;

  @override
  void paint(Canvas canvas, ui.Size size) {
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

    var connector = app.tempConnector ?? TempConnector();

    if (app.tempConnector == null) {
      return;
    }

    for (var module1 in app.project.value.patch.value.modules) {
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
  Connectors(this.app);

  App app;

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
      size: const ui.Size(4000, 2000),
      painter: ConnectorsPainter(widget.app),
    );
  }
}

class ConnectorsPainter extends CustomPainter {
  ConnectorsPainter(this.app);

  App app;

  @override
  void paint(Canvas canvas, ui.Size size) {
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue
      ..strokeWidth = 4;

    for (var connector in app.project.value.patch.value.connectors) {
      for (var module1 in app.project.value.patch.value.modules) {
        if (connector.start.moduleId == module1.id) {
          for (var module2 in app.project.value.patch.value.modules) {
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

              bool selected = module1.id == app.selectedModule ||
                  module2.id == app.selectedModule;

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
  void paint(Canvas canvas, ui.Size size) {
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

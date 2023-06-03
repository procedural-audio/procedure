import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../patch.dart';
import '../main.dart';
import '../projects.dart';

import 'browser.dart';
import 'presets.dart';

class NewTopBar extends StatefulWidget {
  NewTopBar({
    required this.app,
    required this.instViewVisible,
    required this.onViewSwitch,
    required this.onUserInterfaceEdit,
    required this.onProjectClose,
  });

  String projectName = "New Project 1";

  App app;
  bool instViewVisible;
  void Function() onViewSwitch;
  void Function() onUserInterfaceEdit;
  void Function() onProjectClose;

  @override
  _NewTopBar createState() => _NewTopBar();
}

class _NewTopBar extends State<NewTopBar> {
  final double sidebarWidth = 300;
  final double timeBarHeight = 35;

  int rightBarIndex = 0;
  bool rightBarVisible = false;
  bool timeBarVisible = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedPositioned(
          left: 0,
          right: 0,
          top: timeBarVisible ? timeBarHeight : 0,
          curve: Curves.linearToEaseOut,
          duration: const Duration(milliseconds: 300),
          child: TimeBar(
            height: timeBarHeight,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(20, 20, 20, 1.0),
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(30, 30, 30, 1.0),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: IconButton(
                          onPressed: widget.onProjectClose,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: Text(
                          widget.projectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: timeBarVisible
                                ? const Color.fromRGBO(40, 40, 40, 1.0)
                                : const Color.fromRGBO(30, 30, 30, 1.0),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                timeBarVisible = !timeBarVisible;
                              });
                            },
                            icon: const Icon(
                              Icons.alarm,
                              color: Colors.deepPurpleAccent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 400,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(35, 35, 35, 1.0),
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      /*Expanded(child: Container()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(35, 35, 35, 1.0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            children: [
                              MainBarButton(
                                icon: Icons.backspace,
                                color: Colors.white,
                                size: 14,
                                onPressed: () {
                                  print("Backspace");
                                },
                              ),
                              MainBarButton(
                                icon: Icons.play_arrow,
                                color: Colors.green,
                                size: 14,
                                onPressed: () {
                                  print("Backspace");
                                },
                              ),
                              MainBarButton(
                                icon: Icons.pause,
                                color: Colors.white,
                                onPressed: () {
                                  print("Backspace");
                                },
                              ),
                              MainBarButton(
                                icon: Icons.stop,
                                color: Colors.white,
                                onPressed: () {
                                  print("Backspace");
                                },
                              ),
                              MainBarButton(
                                icon: Icons.loop,
                                color: Colors.white,
                                onPressed: () {
                                  print("Backspace");
                                },
                              ),
                            ],
                          ),
                        ),
                      ),*/
                      Expanded(child: Container()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(35, 35, 35, 1.0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            children: [
                              MainBarButton(
                                icon: Icons.graphic_eq,
                                color: rightBarIndex == 1 && rightBarVisible
                                    ? Colors.blue
                                    : Colors.white,
                                size: 14,
                                onPressed: () {
                                  setState(() {
                                    if (rightBarVisible && rightBarIndex == 1) {
                                      rightBarVisible = false;
                                    } else {
                                      rightBarIndex = 1;
                                      rightBarVisible = true;
                                    }
                                  });
                                },
                              ),
                              MainBarButton(
                                icon: Icons.music_note,
                                color: rightBarIndex == 2 && rightBarVisible
                                    ? Colors.blue
                                    : Colors.white,
                                size: 14,
                                onPressed: () {
                                  setState(() {
                                    if (rightBarVisible && rightBarIndex == 2) {
                                      rightBarVisible = false;
                                    } else {
                                      rightBarIndex = 2;
                                      rightBarVisible = true;
                                    }
                                  });
                                },
                              ),
                              MainBarButton(
                                icon: Icons.cable,
                                color: rightBarIndex == 3 && rightBarVisible
                                    ? Colors.blue
                                    : Colors.white,
                                size: 14,
                                onPressed: () {
                                  setState(() {
                                    if (rightBarVisible && rightBarIndex == 3) {
                                      rightBarVisible = false;
                                    } else {
                                      rightBarIndex = 3;
                                      rightBarVisible = true;
                                    }
                                  });
                                },
                              ),
                              MainBarButton(
                                icon: Icons.widgets,
                                color: rightBarIndex == 4 && rightBarVisible
                                    ? Colors.blue
                                    : Colors.white,
                                size: 14,
                                onPressed: () {
                                  setState(() {
                                    if (rightBarVisible && rightBarIndex == 4) {
                                      rightBarVisible = false;
                                    } else {
                                      rightBarIndex = 4;
                                      rightBarVisible = true;
                                    }
                                  });
                                },
                              ),
                              MainBarButton(
                                icon: Icons.widgets,
                                color: rightBarIndex == 5 && rightBarVisible
                                    ? Colors.blue
                                    : Colors.white,
                                size: 14,
                                onPressed: () {
                                  setState(() {
                                    if (rightBarVisible && rightBarIndex == 5) {
                                      rightBarVisible = false;
                                    } else {
                                      rightBarIndex = 5;
                                      rightBarVisible = true;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          top: 40,
          bottom: 0,
          right: rightBarVisible ? 0 : -sidebarWidth,
          curve: Curves.linearToEaseOut,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: sidebarWidth,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(20, 20, 20, 1.0),
              border: Border(
                left: BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
            ),
            child: Stack(
              children: [
                Visibility(
                  visible: rightBarIndex == 1,
                  child: SamplesBrowser(),
                ),
                Visibility(
                  visible: rightBarIndex == 2,
                  child: NotesBrowser(),
                ),
                Visibility(
                  visible: rightBarIndex == 3,
                  child: ModulesBrowser(),
                ),
                Visibility(
                  visible: rightBarIndex == 4,
                  child: WidgetsBrowser(),
                ),
                Visibility(
                  visible: rightBarIndex == 5,
                  child: Settings(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SamplesBrowser extends StatelessWidget {
  const SamplesBrowser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Center(
            child: Text(
              "Samples Browser",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NotesBrowser extends StatelessWidget {
  const NotesBrowser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Center(
            child: Text(
              "Notes Browser",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModulesBrowser extends StatelessWidget {
  const ModulesBrowser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Center(
            child: Text(
              "Modules Browser",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WidgetsBrowser extends StatelessWidget {
  const WidgetsBrowser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Center(
            child: Text(
              "Widgets Browser",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(30, 30, 30, 1.0),
          ),
          child: const Center(
            child: Text(
              "Settings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimeBar extends StatefulWidget {
  const TimeBar({required this.height, Key? key}) : super(key: key);

  final double height;

  @override
  _TimeBar createState() => _TimeBar();
}

class _TimeBar extends State<TimeBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(10, 10, 10, 1.0),
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(30, 30, 30, 1.0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 200,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Color.fromRGBO(30, 30, 30, 1.0),
                  width: 1.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: TimelinePainter(),
            ),
          ),
          Container(
            width: 200,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(30, 30, 30, 1.0),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  int length = 1000;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(60, 60, 60, 1.0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < length; i++) {
      if (i % 4 == 0) {
        canvas.drawLine(
          Offset((size.width / length) * i, 0),
          Offset((size.width / length) * i, 8),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class MainBarButton extends StatefulWidget {
  const MainBarButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 18,
  });

  final IconData icon;
  final Color color;
  final Function onPressed;
  final double? size;

  @override
  _MainBarButton createState() => _MainBarButton();
}

class _MainBarButton extends State<MainBarButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        widget.onPressed();
      },
      icon: Icon(
        widget.icon,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}

class Bar extends StatefulWidget {
  Bar({
    required this.app,
    required this.instViewVisible,
    required this.onViewSwitch,
    required this.onUserInterfaceEdit,
  });

  App app;
  bool instViewVisible;
  void Function() onViewSwitch;
  void Function() onUserInterfaceEdit;

  @override
  _Bar createState() => _Bar();
}

class _Bar extends State<Bar> {
  bool barExpanded = false;

  bool showInstrumentView = false;
  bool showPresetView = false;
  bool showOtherView = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Project?>(
      valueListenable: widget.app.project!,
      builder: (context, project, child) {
        var project = widget.app.project.value!;
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BarButton(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                    ),
                    iconData:
                        widget.instViewVisible ? Icons.cable : Icons.piano,
                    onTap: () {
                      widget.onViewSwitch();
                    },
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: project.info.name,
                    builder: (context, name, child) {
                      return BarDropdown(
                        width: 180,
                        text: name,
                        onTap: () {
                          setState(() {
                            showInstrumentView = !showInstrumentView;
                            showPresetView = false;
                            showOtherView = false;
                          });
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder<Patch>(
                    valueListenable: project.patch,
                    builder: (context, patch, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: patch.info.name,
                        builder: (context, name, child) {
                          return BarDropdown(
                            width: 180,
                            text: name,
                            onTap: () {
                              setState(() {
                                showPresetView = !showPresetView;
                                showInstrumentView = false;
                                showOtherView = false;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  BarButton(
                    iconData: Icons.edit,
                    onTap: () {
                      widget.onUserInterfaceEdit();
                    },
                  ),
                  BarButton(
                    iconData: Icons.save,
                    onTap: () {
                      project.save();
                    },
                  ),
                  BarButton(
                    iconData: showOtherView
                        ? Icons.arrow_drop_down
                        : Icons.arrow_drop_up,
                    onTap: () {
                      setState(() {
                        showOtherView = !showOtherView;
                        showInstrumentView = false;
                        showPresetView = false;
                      });
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10.0),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Visibility(
                visible: showInstrumentView || showPresetView || showOtherView,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
                  child: Container(
                    width: barExpanded ? 710 : 525,
                    height: 600,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                        width: 1,
                        color: const Color.fromRGBO(70, 70, 70, 1.0),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Visibility(
                          visible: showInstrumentView,
                          child: BrowserView(widget.app),
                        ),
                        Visibility(
                          visible: showPresetView,
                          child: PresetsView(
                            patches: project.patches,
                            interfaces: project.interfaces,
                            onLoadPatch: (info) {
                              project.loadPatch(info, widget.app.core);
                            },
                          ),
                        ),
                        Visibility(
                          visible: showOtherView,
                          child: OtherView(widget.app),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BarButton extends StatefulWidget {
  BarButton(
      {required this.iconData,
      required this.onTap,
      this.borderRadius,
      this.iconColor});

  IconData iconData;
  void Function() onTap;
  BorderRadius? borderRadius;
  Color? iconColor;

  @override
  _BarButton createState() => _BarButton();
}

class _BarButton extends State<BarButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() {
        hovering = true;
      }),
      onExit: (e) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastLinearToSlowEaseIn,
          width: 45,
          height: 35,
          decoration: BoxDecoration(
            color: hovering
                ? const Color.fromRGBO(60, 60, 60, 1.0)
                : const Color.fromRGBO(50, 50, 50, 1.0),
            borderRadius: widget.borderRadius,
          ),
          child: Icon(
            widget.iconData,
            color: hovering ? Colors.white : Colors.grey,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class BarDropdown extends StatefulWidget {
  BarDropdown({required this.text, required this.onTap, this.width});

  double? width;
  String text;
  void Function() onTap;

  @override
  _BarDropdown createState() => _BarDropdown();
}

class _BarDropdown extends State<BarDropdown> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() {
        hovering = true;
      }),
      onExit: (e) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 35,
          width: widget.width,
          alignment: Alignment.center,
          color: hovering
              ? const Color.fromRGBO(60, 60, 60, 1.0)
              : const Color.fromRGBO(50, 50, 50, 1.0),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class OtherView extends StatelessWidget {
  OtherView(this.app, {super.key});

  App app;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DefaultTabController(
          initialIndex: 0,
          length: 4,
          child: Scaffold(
            backgroundColor: const Color.fromRGBO(80, 80, 80, 1.0),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Theme(
                data: ThemeData(splashFactory: NoSplash.splashFactory),
                child: AppBar(
                  toolbarHeight: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: const Color.fromRGBO(50, 50, 50, 1.0),
                  bottom: const TabBar(
                    tabs: <Widget>[
                      Tab(
                        text: "Assets",
                      ),
                      Tab(
                        text: "Samples",
                      ),
                      Tab(
                        text: "Plugins",
                      ),
                      Tab(
                        text: "Settings",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              color: const Color.fromRGBO(40, 40, 40, 1.0),
              child: TabBarView(
                children: <Widget>[
                  const Center(
                    child: Text("It's cloudy here"),
                  ),
                  const Center(
                    child: Text("It's rainy here"),
                  ),
                  const Center(
                    child: Text("It's other here"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

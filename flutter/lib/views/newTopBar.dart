import 'package:flutter/material.dart';
import 'package:metasampler/views/presets.dart';

import '../projects.dart';
import 'info.dart';

class NewTopBar extends StatefulWidget {
  NewTopBar({
    required this.projectInfo,
    required this.sidebarDisplay,
    required this.onSidebarChange,
    required this.onViewSwitch,
    required this.onUserInterfaceEdit,
    required this.onProjectClose,
  });

  ProjectInfo projectInfo;
  final ProjectSidebarDisplay sidebarDisplay;

  void Function(ProjectSidebarDisplay) onSidebarChange;
  void Function() onViewSwitch;
  void Function() onUserInterfaceEdit;
  void Function() onProjectClose;

  @override
  _NewTopBar createState() => _NewTopBar();
}

class _NewTopBar extends State<NewTopBar> {
  final double timeBarHeight = 35;

  bool timeBarVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  padding: const EdgeInsets.only(left: 5),
                  child: IconButton(
                    onPressed: widget.onProjectClose,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ValueListenableBuilder<String>(
                    valueListenable: widget.projectInfo.name,
                    builder: (context, projectName, child) {
                      return Text(
                        projectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      );
                    },
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
          PresetsButton(),
          Expanded(
            child: Row(
              children: [
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
                          color: widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Samples
                              ? Colors.blue
                              : Colors.white,
                          size: 14,
                          onPressed: () {
                            setState(() {
                              if (widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Samples) {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.None,
                                );
                              } else {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.Samples,
                                );
                              }
                            });
                          },
                        ),
                        MainBarButton(
                          icon: Icons.music_note,
                          color: widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Notes
                              ? Colors.blue
                              : Colors.white,
                          size: 14,
                          onPressed: () {
                            setState(() {
                              if (widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Notes) {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.None,
                                );
                              } else {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.Notes,
                                );
                              }
                            });
                          },
                        ),
                        MainBarButton(
                          icon: Icons.cable,
                          color: widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Modules
                              ? Colors.blue
                              : Colors.white,
                          size: 14,
                          onPressed: () {
                            setState(() {
                              if (widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Modules) {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.None,
                                );
                              } else {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.Modules,
                                );
                              }
                            });
                          },
                        ),
                        MainBarButton(
                          icon: Icons.widgets,
                          color: widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Widgets
                              ? Colors.blue
                              : Colors.white,
                          size: 14,
                          onPressed: () {
                            setState(() {
                              if (widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Widgets) {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.None,
                                );
                              } else {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.Widgets,
                                );
                              }
                            });
                          },
                        ),
                        MainBarButton(
                          icon: Icons.widgets,
                          color: widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Settings
                              ? Colors.blue
                              : Colors.white,
                          size: 14,
                          onPressed: () {
                            setState(() {
                              if (widget.sidebarDisplay ==
                                  ProjectSidebarDisplay.Settings) {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.None,
                                );
                              } else {
                                widget.onSidebarChange(
                                  ProjectSidebarDisplay.Settings,
                                );
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
    );
    /*return Stack(
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
                        padding: const EdgeInsets.only(left: 5),
                        child: IconButton(
                          onPressed: widget.onProjectClose,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.projectInfo.name,
                          builder: (context, projectName, child) {
                            return Text(
                              projectName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            );
                          },
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
                PresetsButton(),
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
        /*AnimatedPositioned(
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
        ),*/
      ],
    );*/
  }
}

class PresetsButton extends StatefulWidget {
  const PresetsButton({Key? key}) : super(key: key);

  @override
  _PresetsButton createState() => _PresetsButton();
}

class _PresetsButton extends State<PresetsButton> {
  bool hovering = false;
  bool expanded = false;
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
          print("Presets");
        },
        child: Container(
          width: 400,
          height: 30,
          decoration: BoxDecoration(
            color: (hovering || expanded)
                ? const Color.fromRGBO(40, 40, 40, 1.0)
                : const Color.fromRGBO(30, 30, 30, 1.0),
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:metasampler/views/presets.dart';

import '../patch.dart';
import '../projects.dart';
import 'info.dart';

const double barHeight = 35;

class NewTopBar extends StatefulWidget {
  NewTopBar({
    required this.loadedPatch,
    required this.projectInfo,
    required this.sidebarDisplay,
    required this.onPresetsButtonTap,
    required this.onSidebarChange,
    required this.onViewSwitch,
    required this.onUserInterfaceEdit,
    required this.onSave,
    required this.onProjectClose,
  });

  ProjectInfo projectInfo;
  ValueNotifier<Patch> loadedPatch;
  final ProjectSidebarDisplay sidebarDisplay;

  void Function(ProjectSidebarDisplay) onSidebarChange;
  void Function() onPresetsButtonTap;
  void Function() onViewSwitch;
  void Function() onUserInterfaceEdit;
  void Function() onSave;
  void Function() onProjectClose;

  @override
  _NewTopBar createState() => _NewTopBar();
}

class _NewTopBar extends State<NewTopBar> {
  bool timeBarVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ProjectCloseButton(
                    info: widget.projectInfo,
                    onTap: widget.onProjectClose,
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          PresetsButton(
            loadedPatch: widget.loadedPatch,
            onTap: widget.onPresetsButtonTap,
            onSave: widget.onSave,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container()),
                /*Padding(
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
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BarButton extends StatefulWidget {
  const BarButton({
    required this.icon,
    required this.borderRadius,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final Icon icon;
  final void Function() onTap;
  final BorderRadius borderRadius;

  @override
  _BarButton createState() => _BarButton();
}

class _BarButton extends State<BarButton> {
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
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: barHeight,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: BoxDecoration(
            color: hovering
                ? const Color.fromRGBO(50, 50, 50, 1.0)
                : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: widget.icon,
        ),
      ),
    );
  }
}

class ProjectCloseButton extends StatefulWidget {
  const ProjectCloseButton({
    required this.info,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final void Function() onTap;
  final ProjectInfo info;

  @override
  _ProjectCloseButton createState() => _ProjectCloseButton();
}

class _ProjectCloseButton extends State<ProjectCloseButton> {
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
        onTap: widget.onTap,
        child: Container(
          height: barHeight,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: BoxDecoration(
            color: hovering
                ? const Color.fromRGBO(40, 40, 40, 1.0)
                : const Color.fromRGBO(30, 30, 30, 1.0),
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: hovering
                    ? Colors.white
                    : const Color.fromRGBO(200, 200, 200, 1.0),
                size: 12,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 2),
                child: ValueListenableBuilder<String>(
                  valueListenable: widget.info.name,
                  builder: (context, projectName, child) {
                    return Text(
                      projectName,
                      style: TextStyle(
                        color: hovering
                            ? Colors.white
                            : const Color.fromRGBO(200, 200, 200, 1.0),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PresetsButton extends StatefulWidget {
  const PresetsButton({
    required this.loadedPatch,
    required this.onTap,
    required this.onSave,
    Key? key,
  }) : super(key: key);

  final ValueNotifier<Patch> loadedPatch;
  final void Function() onTap;
  final void Function() onSave;

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
        onTap: widget.onTap,
        child: Container(
          width: 450,
          height: barHeight,
          decoration: BoxDecoration(
            color: (hovering || expanded)
                ? const Color.fromRGBO(40, 40, 40, 1.0)
                : const Color.fromRGBO(30, 30, 30, 1.0),
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: Row(
            children: [
              BarButton(
                icon: const Icon(
                  Icons.cable,
                  size: 17,
                  color: Colors.grey,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(0)),
                onTap: () {},
              ),
              BarButton(
                icon: const Icon(
                  Icons.alarm,
                  size: 18,
                  color: Colors.deepPurpleAccent,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(0)),
                onTap: () {},
              ),
              Expanded(
                child: ValueListenableBuilder<Patch>(
                  valueListenable: widget.loadedPatch,
                  builder: (context, patch, child) {
                    return ValueListenableBuilder<String>(
                      valueListenable: patch.info.name,
                      builder: (context, name, child) {
                        return Center(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              BarButton(
                icon: const Icon(
                  Icons.save,
                  size: 17,
                  color: Colors.grey,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(0)),
                onTap: () {
                  widget.onSave();
                },
              ),
              BarButton(
                icon: const Icon(
                  Icons.arrow_downward,
                  size: 18,
                  color: Colors.grey,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(0)),
                onTap: () {},
              ),
            ],
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

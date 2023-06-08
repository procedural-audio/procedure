import 'package:flutter/material.dart';
import 'package:metasampler/patch.dart';
import 'package:metasampler/views/newTopBar.dart';

import 'dart:math';

import 'core.dart';
import 'projects.dart';
import 'plugins.dart';

import 'views/info.dart';
import 'views/projects.dart';
import 'views/settings.dart';

import 'ui/ui.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  PLUGINS.list();

  if (args.isEmpty) {
    runApp(
      App(
        core: Core.create(),
        assets: Assets.platformDefault(),
        project: ValueNotifier(null),
      ),
    );
  } else {
    var addr = int.parse(args[0].split(": ").last);
    runApp(
      App(
        core: Core.from(addr),
        assets: Assets.platformDefault(),
        project: ValueNotifier(null),
      ),
    );
  }
}

class App extends StatelessWidget {
  App({required this.core, required this.assets, required this.project}) {
    PLUGINS.addListener(
      () {
        print("Regenerating patch");
        var currentProject = project.value;
        if (currentProject != null) {
          currentProject.patch.value.disableTick();

          var oldPatch = currentProject.patch.value;
          var newPatch = Patch.from(oldPatch.info);
          var state = oldPatch.rawPatch.getState();

          newPatch.rawPatch.setState(state);
          currentProject.patch.value = newPatch;
          core.setPatch(newPatch);
        }
      },
    );
  }

  final Core core;
  final Assets assets;
  final ValueNotifier<Project?> project;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashColor: const Color.fromRGBO(20, 20, 20, 1.0),
      ),
      home: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        body: Window(this),
      ),
    );
  }
}

class Window extends StatefulWidget {
  Window(this.app);

  App app;

  @override
  State<Window> createState() => _Window();
}

class _Window extends State<Window> {
  bool uiVisible = false;

  void loadProject(ProjectInfo info) async {
    var project = await Project.load(info, widget.app.core);
    if (project != null) {
      widget.app.core.setPatch(project.patch.value);
      widget.app.project.value?.patch.value.disableTick();
      widget.app.project.value = project;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Material(
            color: const Color.fromRGBO(10, 10, 10, 1.0),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: NewTopBar(
                    app: widget.app,
                    instViewVisible: uiVisible,
                    onViewSwitch: () {
                      setState(() {
                        uiVisible = !uiVisible;
                      });
                    },
                    onUserInterfaceEdit: () {
                      project.ui.value?.toggleEditing();
                    },
                    onProjectClose: unloadProject,
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (uiVisible) {
                        return ValueListenableBuilder<UserInterface?>(
                          valueListenable: project.ui,
                          builder: (context, ui, child) {
                            if (ui != null) {
                              return ui;
                            } else {
                              return Container();
                            }
                          },
                        );
                      } else {
                        return ValueListenableBuilder<Patch>(
                          valueListenable: project.patch,
                          builder: (context, patch, child) {
                            return patch;
                          },
                        );
                      }
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

  void unloadProject() async {
    Navigator.pop(context);

    widget.app.project.value?.info.date.value = DateTime.now();
    await widget.app.project.value?.info.save();
    await widget.app.project.value?.patch.value.info.save();

    widget.app.project.value?.patch.value.disableTick();
    widget.app.project.value = null;
    widget.app.core.setPatch(null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: const Color.fromRGBO(10, 10, 10, 1.0),
          child: ValueListenableBuilder<Project?>(
            valueListenable: widget.app.project,
            builder: (context, project, child) {
              return ProjectsBrowser(
                app: widget.app,
                onLoadProject: loadProject,
              );
            },
          ),
        ),
      ],
    );
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

      children.add(
        Positioned(
          left: x + width / 2,
          top: y + height / 2,
          child: Container(
            width: elementWidth,
            height: elementHeight,
            alignment: Alignment.center,
            child: Text(
              module,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(60, 60, 60, 0.5),
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
        ),
      );

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
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    border: Border.all(
                      color: const Color.fromRGBO(200, 200, 200, 0.5),
                      width: 2.0,
                    ),
                  ),
                ),
              )
            ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'globals.dart';
import 'core.dart';
import 'projects.dart';

import 'views/info.dart';
import 'views/projects.dart';

import 'package:metasampler/src/rust/api/simple.dart';
import 'package:metasampler/src/rust/frb_generated.dart';

Future<void> main(List<String> args) async {
  await RustLib.init();
  CmajorLibrary.load(
      path:
          "/Users/chasekanipe/Github/cmajor-rs/cmajor/x64/libCmajPerformer.dylib");

  WidgetsFlutterBinding.ensureInitialized();

  Plugins.scan(Settings2.pluginDirectory());

  print("Rust backend says: " + greet(name: "Tom"));

  if (args.isEmpty) {
    runApp(
      App(
        project: ValueNotifier(null),
      ),
    );
  } else {
    var addr = int.parse(args[0].split(": ").last);
    // globals.core = Core.from(addr);

    runApp(
      App(
        project: ValueNotifier(null),
      ),
    );
  }
}

class App extends StatelessWidget {
  App({required this.project}) {
    Directory(Settings2.pluginDirectory()).watch(recursive: true).listen(
      (event) {
        if (event is FileSystemModifyEvent) {
          if (event.contentChanged) {
            print("Plugins directory changed");
            Plugins.scan(Settings2.pluginDirectory());
          }
        }
      },
    );

    Plugins.list().addListener(
      () async {
        var presetInfo = project.value?.preset.value.info;

        if (presetInfo != null) {
          var preset = await Preset.load(presetInfo);
          if (preset != null) {
            project.value?.preset.value = preset;
          }
        }
      },
    );
  }

  final ValueNotifier<Project?> project;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color.fromRGBO(20, 20, 20, 1.0),
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
    var project = await Project.load(info, unloadProject);

    if (project != null) {
      // widget.app.core.setPatch(project.preset.value.patch);
      widget.app.project.value = project;

      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: "/project"),
          builder: (context) => Theme(
            data: ThemeData(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: Material(
              color: const Color.fromRGBO(10, 10, 10, 1.0),
              child: project,
            ),
          ),
        ),
      );
    }
  }

  void unloadProject() async {
    /*Navigator.pop(context);

    widget.app.project.value = null;
    widget.app.core.setPatch(null);

    setState(() {});*/
  }

  @override
  Widget build(BuildContext context) {
    return ProjectsBrowser(
      app: widget.app,
      onLoadProject: loadProject,
    );
  }
}

/*class ModuleWheel extends StatefulWidget {
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
*/

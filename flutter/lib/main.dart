import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'projects.dart';

import 'views/info.dart';
import 'views/projects.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';

Future<void> main(List<String> args) async {
  await RustLib.init();

  print("In flutter main with arguments: " + args.toString());

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
    // var addr = int.tryParse(args[0].split(": ").last);
    // globals.core = Core.from(addr);

    runApp(
      App(
        project: ValueNotifier(null),
      ),
    );
  }
}

class App extends StatelessWidget {
  App({super.key, required this.project}) {
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
  Window(this.app, {super.key});

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
    Navigator.pop(context);
    // TODO: Save the project here
    widget.app.project.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return ProjectsBrowser(
      app: widget.app,
      onLoadProject: loadProject,
    );
  }
}

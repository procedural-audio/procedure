import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metasampler/settings.dart';

import 'project/project.dart';
import 'project/browser.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api/io.dart';

Future<void> main(List<String> args) async {
  await RustLib.init();

  WidgetsFlutterBinding.ensureInitialized();
  AudioManager audioManager = AudioManager();

  runApp(
    App(
      project: ValueNotifier(null),
      audioManager: audioManager,
    ),
  );
}

class App extends StatelessWidget {
  App({super.key, required this.project, required this.audioManager});

  final ValueNotifier<Project?> project;
  final AudioManager? audioManager;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        showProjectBrowser(MainDirectory(Directory("/Users/chase/Music/Procedural Audio")));
      },
    );
  }

  @override
  void dispose() async {
    super.dispose();
  }

  void showProjectBrowser(MainDirectory directory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: "/projects"),
        builder: (context) => Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Material(
            color: const Color.fromRGBO(10, 10, 10, 1.0),
            child: ProjectsBrowser(directory, audioManager: widget.app.audioManager),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          var picked = await FilePicker.platform.getDirectoryPath();
          if (picked != null && picked.isNotEmpty) {
            var dir = Directory(picked);
            var main = MainDirectory(dir);
            showProjectBrowser(main);
          }
        },
        child: const Text("Browse"),
      ),
    );
  }
}

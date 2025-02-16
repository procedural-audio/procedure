import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:metasampler/bindings/api/graph.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';
import 'package:path_provider/path_provider.dart';

import 'patch/module.dart';
import 'projects.dart';

import 'views/info.dart';
import 'views/projects.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';

Future<void> main(List<String> args) async {
  await RustLib.init();

  print("In flutter main with arguments: " + args.toString());

  WidgetsFlutterBinding.ensureInitialized();

  // Plugins.scan();
  // Plugins.beginWatch();

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

    // rlugins.endWatch();
  }
}

class App extends StatelessWidget {
  App({super.key, required this.project});

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

  @override
  void initState() {
    super.initState();
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
            child: ProjectsBrowser(directory),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeDirectoryBrowser(
      onUpdateDirectory: (dir) {
        showProjectBrowser(dir);
      },
    );
  }
}

class HomeDirectoryBrowser extends StatelessWidget {
  HomeDirectoryBrowser({required this.onUpdateDirectory, super.key});

  void Function(MainDirectory) onUpdateDirectory;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          var picked = await FilePicker.platform.getDirectoryPath();
          if (picked != null && picked.isNotEmpty) {
            onUpdateDirectory(MainDirectory(Directory(picked)));
          }
        },
        child: const Text("Browse for projects"),
      ),
    );
  }
}

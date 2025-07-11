import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metasampler/home.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/style/colors.dart';

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
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: ZoomPageTransitionsBuilder(
              backgroundColor: AppColors.background,
            ),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(
              backgroundColor: AppColors.background,
            ),
          },
        ),
      ),
      builder: (context, child) {
        // Wrap the entire app with TitleBar so it stays on top of all routes
        return Scaffold(
          backgroundColor: AppColors.background,
          body: TitleBar(
            child: ClipRect(
              child: child ?? Container()
            )
          ),
        );
      },
      home: HomeWidget(audioManager: audioManager),
    );
  }
}

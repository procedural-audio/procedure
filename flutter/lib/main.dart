import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metasampler/home.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/style/colors.dart';

import 'project/project.dart';
import 'titleBar.dart';
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
      navigatorObservers: [TitleBar.navigatorObserver],
      theme: ThemeData(
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        canvasColor: AppColors.backgroundDark,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: ZoomPageTransitionsBuilder(
              backgroundColor: AppColors.backgroundDark,
            ),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(
              backgroundColor: AppColors.backgroundDark,
            ),
          },
        ),
      ),
      builder: (context, child) {
        // Create TitleBar with observer callback
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => TitleBarWrapper(
                  child: ClipRect(
                    child: child ?? Container()
                  )
                ),
              ),
            ],
          ),
        );
      },
      home: HomeWidget(audioManager: audioManager),
    );
  }
}

class TitleBarWrapper extends StatelessWidget {
  const TitleBarWrapper({super.key, required this.child});
  
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return TitleBar(child: child);
  }
}

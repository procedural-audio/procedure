import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:procedure_ui/auth_gate.dart';
import 'package:procedure_ui/home.dart';
import 'package:procedure_ui/settings.dart';
import 'package:procedure_ui/settings/settings.dart';
import 'package:procedure_ui/style/colors.dart';
import 'package:procedure_ui/window.dart';

import 'project/project.dart';
import 'project/info.dart';
import 'titleBar.dart';
import 'project/browser.dart';

import 'package:procedure_bindings/bindings/frb_generated.dart';
import 'package:procedure_bindings/bindings/api/io.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

late AudioManager _audioManager;

final GoRouter _router = GoRouter(
  initialLocation: '/projects',
  observers: [TitleBar.navigatorObserver],
  routes: [
    ShellRoute(
      builder: (context, state, child) => Window(child: child),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => HomeWidget(
            audioManager: _audioManager,
            child: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/login',
                  builder: (context, state) => AuthGate(clientId: clientId),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/projects',
                  builder: (context, state) => ProjectsBrowser(audioManager: _audioManager),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/modules',
                  builder: (context, state) => ModulesPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/samples',
                  builder: (context, state) => SamplesPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/community',
                  builder: (context, state) => CommunityPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => SettingsWidget(audioManager: _audioManager),
                ),
              ],
            ),
          ],
        ),
        // Minimal loader: '/project/:projectName' redirects to first preset
        GoRoute(
          path: '/project/:projectName',
          builder: (context, state) {
            final projectName = Uri.decodeComponent(state.pathParameters['projectName']!);
            return FutureBuilder<Project?>(
              future: _loadProject(projectName),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    color: const Color.fromRGBO(10, 10, 10, 1.0),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.connectionState == ConnectionState.done && snapshot.data == null) {
                  context.go('/projects');
                } else if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  print("Loaded project $projectName");
                  return snapshot.data!;
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
        GoRoute(
          path: '/project/:projectName/preset/:presetName',
          builder: (context, state) {
            final projectName = Uri.decodeComponent(state.pathParameters['projectName']!);
            final presetName = Uri.decodeComponent(state.pathParameters['presetName']!);
            return FutureBuilder<Project?>(
              future: _loadProject(projectName),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    color: const Color.fromRGBO(10, 10, 10, 1.0),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.connectionState == ConnectionState.done && snapshot.data == null) {
                  context.go('/projects');
                } else if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return snapshot.data!;
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ],
    ),
  ],
);

Future<Project?> _loadProject(String projectName) async {
  try {
    final projectsDir = await SettingsService.getProjectsDirectory();
    if (projectsDir == null) return null;

    final projectDirectory = Directory('$projectsDir/$projectName');
    if (!await projectDirectory.exists()) return null;

    final projectInfo = await ProjectInfo.load(projectDirectory);
    if (projectInfo == null) return null;

    final mainDir = Directory(projectsDir).parent;
    final tempMainDirectory = MainDirectory(mainDir);

    final project = await Project.load(projectInfo, tempMainDirectory, _audioManager);
    return project;
  } catch (e) {
    print('Error loading project $projectName: $e');
    return null;
  }
}

Future<Project?> _loadPreset(String projectName, String presetName) async {
  return await _loadProject(projectName);
}

Future<String?> _firstPresetName(String projectName) async {
  try {
    final projectsDir = await SettingsService.getProjectsDirectory();
    if (projectsDir == null) return null;
    final presetsDir = Directory('$projectsDir/$projectName/presets');
    if (!await presetsDir.exists()) return null;
    final entries = await presetsDir.list().toList();
    final dirs = entries.whereType<Directory>().toList()
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    if (dirs.isEmpty) return null;
    final name = dirs.first.uri.pathSegments.isNotEmpty
        ? dirs.first.uri.pathSegments.last
        : dirs.first.path.split(Platform.pathSeparator).last;
    return name.isEmpty ? null : name;
  } catch (_) {
    return null;
  }
}

const clientId = 'YOUR_CLIENT_ID';

Future<void> runProcedureApp(List<String> args) async {
  await RustLib.init();

  WidgetsFlutterBinding.ensureInitialized();
  _audioManager = AudioManager();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );


  // Ideal time to initialize
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());

  runApp(App());
}

class NoBounceScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.android) {
      return const BouncingScrollPhysics();
    }
    return const ClampingScrollPhysics();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      scrollBehavior: NoBounceScrollBehavior(),
      title: 'Procedure',
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
    );
  }
}

// Placeholder pages
class ModulesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text('Modules Page - Coming Soon'),
      ),
    );
  }
}

class SamplesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text('Samples Page - Coming Soon'),
      ),
    );
  }
}

class CommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text('Community Page - Coming Soon'),
      ),
    );
  }
}

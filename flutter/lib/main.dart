import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:metasampler/home.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/settings/settings.dart';
import 'package:metasampler/style/colors.dart';
import 'package:metasampler/window.dart';

import 'project/project.dart';
import 'project/info.dart';
import 'titleBar.dart';
import 'project/browser.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api/io.dart';
import 'package:metasampler/settings.dart' as old_settings;

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
        GoRoute(
          path: '/project/:projectName/preset/:presetName',
          builder: (context, state) {
            final projectName = Uri.decodeComponent(state.pathParameters['projectName']!);
            final presetName = Uri.decodeComponent(state.pathParameters['presetName']!);
            
            // If no project data, show loading or redirect to projects
            return FutureBuilder<Project?>(
              future: _loadProject(projectName, presetName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: const Color.fromRGBO(10, 10, 10, 1.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  return Theme(
                    data: ThemeData(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: Material(
                      color: const Color.fromRGBO(10, 10, 10, 1.0),
                      child: snapshot.data!,
                    ),
                  );
                } else {
                  // Project not found, redirect to projects
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.go('/projects');
                  });

                  return Container();
                }
              },
            );
          },
        ),
      ],
    ),
  ],
);

Future<Project?> _loadProject(String projectName, String presetName) async {
  try {
    // Get projects directory
    final projectsDir = await old_settings.SettingsService.getProjectsDirectory();
    if (projectsDir == null) return null;
    
    // Find project directory
    final projectDirectory = Directory('$projectsDir/$projectName');
    if (!await projectDirectory.exists()) return null;
    
    // Load project info
    final projectInfo = await ProjectInfo.load(projectDirectory);
    if (projectInfo == null) return null;
    
    // Load project with main directory
    final mainDir = Directory(projectsDir).parent;
    final tempMainDirectory = old_settings.MainDirectory(mainDir);
    
    final project = await Project.load(projectInfo, tempMainDirectory, _audioManager);
    return project;
  } catch (e) {
    print('Error loading project $projectName: $e');
    return null;
  }
}

Future<void> main(List<String> args) async {
  await RustLib.init();

  WidgetsFlutterBinding.ensureInitialized();
  _audioManager = AudioManager();

  runApp(App());
}

class NoBounceScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    // Enable bounce on mobile (iOS/Android), clamp on desktop
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

// Custom page for no transitions
class NoTransitionPage<T> extends Page<T> {
  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

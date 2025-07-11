import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MainDirectory {
  MainDirectory(this.main);

  Directory main;

  Directory get projects => Directory(main.path + "/Projects");
  Directory get plugins => Directory(main.path + "/Plugins");
  Directory get assets => Directory(main.path + "/Assets");
  File get settings => File(main.path + "/settings.json");
}

class MainSettings {
  MainSettings(this.file);

  File file;

  static Future<MainSettings?> load(File file) async {
    if (await file.exists()) {
      // Load the settings
    }

    return MainSettings(file);
  }

  void save() async {
    if (!await file.exists()) {
      await file.create();
    }

    // Write the settings
  }
}

class GlobalSettings {
  static double gridSize = 70.0;

  static File get vsCodePath {
    if (Platform.isLinux) {
      return File("/usr/bin/code");
    } else if (Platform.isMacOS) {
      return File(
        "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
      );
    } else {
      print("VS Code path unknown on platform");
      exit(1);
    }
  }
}

class SettingsService {
  static const String _projectsDirectoryKey = 'projects_directory';
  static const String _pluginsDirectoryKey = 'plugins_directory';
  static const String _samplesDirectoryKey = 'samples_directory';

  static SharedPreferences? _prefs;
  
  // Notifier for projects directory changes
  static final ValueNotifier<String?> projectsDirectoryNotifier = ValueNotifier<String?>(null);

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Initialize the notifier with the current projects directory
    projectsDirectoryNotifier.value = _prefs!.getString(_projectsDirectoryKey);
  }

  static Future<String?> getProjectsDirectory() async {
    await initialize();
    return _prefs!.getString(_projectsDirectoryKey);
  }

  static Future<String?> getPluginsDirectory() async {
    await initialize();
    return _prefs!.getString(_pluginsDirectoryKey);
  }

  static Future<String?> getSamplesDirectory() async {
    await initialize();
    return _prefs!.getString(_samplesDirectoryKey);
  }

  static Future<void> setProjectsDirectory(String path) async {
    await initialize();
    await _prefs!.setString(_projectsDirectoryKey, path);
    // Notify listeners that projects directory has changed
    projectsDirectoryNotifier.value = path;
  }

  static Future<void> setPluginsDirectory(String path) async {
    await initialize();
    await _prefs!.setString(_pluginsDirectoryKey, path);
  }

  static Future<void> setSamplesDirectory(String path) async {
    await initialize();
    await _prefs!.setString(_samplesDirectoryKey, path);
  }

  static Future<void> clearDirectories() async {
    await initialize();
    await _prefs!.remove(_projectsDirectoryKey);
    await _prefs!.remove(_pluginsDirectoryKey);
    await _prefs!.remove(_samplesDirectoryKey);
    // Notify that projects directory has been cleared
    projectsDirectoryNotifier.value = null;
  }

  static Future<void> createDirectoriesIfNeeded() async {
    final projectsDir = await getProjectsDirectory();
    final pluginsDir = await getPluginsDirectory();
    final samplesDir = await getSamplesDirectory();

    final directories = [
      if (projectsDir != null) Directory(projectsDir),
      if (pluginsDir != null) Directory(pluginsDir),
      if (samplesDir != null) Directory(samplesDir),
    ];

    for (final dir in directories) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  static Future<Map<String, String?>> getAllDirectories() async {
    return {
      'projects': await getProjectsDirectory(),
      'plugins': await getPluginsDirectory(),
      'samples': await getSamplesDirectory(),
    };
  }
}
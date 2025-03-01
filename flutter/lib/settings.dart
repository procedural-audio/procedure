import 'dart:io';

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
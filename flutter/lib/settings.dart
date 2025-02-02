import 'dart:io';

class GlobalSettings {
  static double gridSize = 70.0;

  static Directory get mainDirectory {
    if (Platform.isLinux) {
      return Directory("~/Procedural Audio");
    } else if (Platform.isMacOS) {
      return Directory("/Users/chasekanipe/Procedural Audio");
    } else {
      print("main directory location unknown on platform");
      exit(1);
    }
  }

  static Directory get pluginsDirectory {
    return Directory("${mainDirectory.path}/Plugins");
  }

  static Directory get projectsDirectory {
    return Directory("${mainDirectory.path}/Projects");
  }

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

  static String coreLibraryDirectory() {
    if (Platform.isLinux) {
      return "/home/chase/github/nodus/build/out/core/release/libtonevision_core.so";
    } else if (Platform.isMacOS) {
      return "/Users/chasekanipe/Github/nodus/build/out/core/release/libtonevision_core.dylib";
    } else {
      print("Core library location unknown on platform");
      exit(1);
    }
  }

  static String cmajorLibrary() {
    if (Platform.isLinux) {
      return "/home/chase/github/cmajor-rs/cmajor/x64/libCmajPerformer.so";
    } else if (Platform.isMacOS) {
      return "/Users/chasekanipe/Github/cmajor-rs/cmajor/x64/libCmajPerformer.dylib";
    } else {
      print("Cmajor library location unknown on platform");
      exit(1);
    }
  }
}

import 'dart:io';

class Settings2 {
  static String pluginDirectory() {
    if (Platform.isLinux) {
      return "/home/chase/github/nodus/modules/";
    } else if (Platform.isMacOS) {
      return "/Users/chasekanipe/Github/nodus/modules/";
    } else {
      print("Core library location unknown on platform");
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

  static String projectsDirectory() {
    if (Platform.isLinux) {
      return "/home/chase/github/assets/projects";
    } else if (Platform.isMacOS) {
      return "/Users/chasekanipe/Github/assets/projects";
    } else {
      print("Projects directory location unknown on platform");
      exit(1);
    }
  }
}

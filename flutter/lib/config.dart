import 'dart:io';
import 'views/presets.dart';

String contentPath = Platform.isLinux
    ? "/home/chase/github/assets/"
    : Platform.isMacOS
        ? "/Users/chasekanipe/Github/content/"
        : "";

List<PresetDirectory> presetDirs = [];

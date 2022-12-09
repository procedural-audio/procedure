import 'dart:io';
import 'views/presets.dart';

String contentPath = Platform.isLinux
    ? "/home/chase/github/content"
    : Platform.isMacOS
        ? "/Users/chasekanipe/Github/metasampler/content"
        : "";

List<PresetDirectory> presetDirs = [];

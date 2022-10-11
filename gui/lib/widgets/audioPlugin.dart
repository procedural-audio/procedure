import 'dart:io';

import 'package:flutter/material.dart';

import 'widget.dart';
import 'dart:ffi';
import '../host.dart';

void Function(FFIWidgetPointer) ffiAudioPluginShowGui = core
    .lookup<NativeFunction<Void Function(FFIWidgetPointer)>>(
        "ffi_audio_plugin_show_gui")
    .asFunction();

class AudioPluginWidget extends ModuleWidget {
  AudioPluginWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  void showGui() async {
    ffiAudioPluginShowGui(widgetRaw.pointer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey,
        child: GestureDetector(onTap: () {
          print("Showing gui");
          setState(() {
            showGui();
          });
        }));
  }
}

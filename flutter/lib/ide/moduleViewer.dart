import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/plugins.dart';

import '../module/node.dart';
import '../module/module.dart';
import '../patch/patch.dart';
import '../views/presets.dart';

class ModuleViewer extends StatefulWidget {
  const ModuleViewer({required this.module, Key? key}) : super(key: key);

  final ValueNotifier<Module?> module;

  @override
  _ModuleViewerState createState() => _ModuleViewerState();
}

class _ModuleViewerState extends State<ModuleViewer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ValueListenableBuilder<Module?>(
          valueListenable: widget.module,
          builder: (context, module, child) {
            if (module == null) {
              return Text("Select a module");
            }

            print("Creating node for module ${module.name}");

            return Node(
              module: module,
              patch: Patch(
                info: PresetInfo.blank(Directory("")),
              ),
              onAddConnector: (p0, p1) => {},
              onRemoveConnections: (p) => {},
              onDrag: (offset) => {},
            );
          },
        ),
      ),
      color: Color.fromRGBO(10, 10, 10, 1.0),
    );
  }
}

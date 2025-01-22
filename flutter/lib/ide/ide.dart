import 'dart:io';

import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:metasampler/bindings/api/graph.dart';
import 'package:metasampler/ide/moduleList.dart';
import 'package:metasampler/ide/moduleViewer.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';

import '../module/module.dart';
import '../module/node.dart';
import 'chat.dart';
import 'codeEditor.dart';

class Ide extends StatefulWidget {
  Ide({required this.onClose, Key? key}) : super(key: key);

  final void Function() onClose;

  @override
  State<Ide> createState() => _IdeState();
}

class _IdeState extends State<Ide> {
  @override
  Widget build(BuildContext context) {
    // Far left has the tree of plugins and modules
    // Center is a large display of EITHER the module being edited OR that module in the project window
    // Right is a collapsible code editor
    // Somewhere is the chat window

    final ValueNotifier<Module?> selectedModule = ValueNotifier(null);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Integrated Development Environment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModuleListSidebar(
            selectedModule: selectedModule,
          ),
          Expanded(
            child: ModuleViewer(
              module: selectedModule,
            ),
          ),
          CodeEditor(),
        ],
      ),
    );
  }
}

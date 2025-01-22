import 'dart:io';

import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:metasampler/bindings/api/graph.dart';
import 'package:metasampler/ide/moduleViewer.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';

import 'chat.dart';
import 'codeEditor.dart';

class Ide extends StatefulWidget {
  const Ide({required this.onClose, Key? key}) : super(key: key);

  final void Function() onClose;

  @override
  State<Ide> createState() => _IdeState();
}

class _IdeState extends State<Ide> {
  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: ModuleViewer(),
          ),
          CodeEditor(),
        ],
      ),
    );
  }
}

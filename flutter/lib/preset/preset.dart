import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../interface/ui.dart';
import '../patch/patch.dart';
import '../plugin/plugin.dart';
import '../bindings/api/node.dart' as rust_node;
import '../bindings/api/cable.dart';
import '../bindings/api/io.dart';
import '../bindings/api/patch.dart';
import 'info.dart';

class Preset extends StatelessWidget {
  final PresetInfo info;
  final Patch patch;
  final ValueNotifier<UserInterface?> interface;
  final bool uiVisible;
  final List<Plugin> plugins;
  final AudioManager? audioManager;
  // Deprecated: editor now receives an initialized Patch directly

  Preset({
    required this.info,
    required this.patch,
    required this.interface,
    required this.uiVisible,
    required this.plugins,
    this.audioManager,
  });

  static Preset from(PresetInfo info, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) {
    // Create empty nodes and cables lists
    return Preset(
      info: info,
      patch: Patch(),
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  static Future<Preset?> load(PresetInfo info, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) async {
    List<rust_node.Node> nodes = [];
    List<Cable> cables = [];
    
    // Try to load existing patch file
    if (await info.patchFile.exists()) {
      try {
        var contents = await info.patchFile.readAsString();
        final json = (contents.isNotEmpty) ? (jsonDecode(contents) as Map<String, dynamic>) : {};
        final List<dynamic> nodesJson = (json['nodes'] as List?) ?? [];
        final List<dynamic> cablesJson = (json['cables'] as List?) ?? [];

        // Rebuild nodes using Rust-side JSON constructor
        for (final n in nodesJson) {
          final node = rust_node.Node.fromJson(json: jsonEncode(n));
          if (node != null) nodes.add(node);
        }

        // Node lookup map
        final Map<int, rust_node.Node> idToNode = { for (final n in nodes) n.id: n };

        // Rebuild cables by endpoint annotation
        for (final c in cablesJson) {
          final srcId = (c['srcNodeId'] as num?)?.toInt();
          final dstId = (c['dstNodeId'] as num?)?.toInt();
          final srcAnn = c['srcAnnotation'] as String?;
          final dstAnn = c['dstAnnotation'] as String?;
          if (srcId == null || dstId == null || srcAnn == null || dstAnn == null) continue;
          final srcNode = idToNode[srcId];
          final dstNode = idToNode[dstId];
          if (srcNode == null || dstNode == null) continue;

          final srcEp = srcNode.getOutputByAnnotation(annotation: srcAnn);
          final dstEp = dstNode.getInputByAnnotation(annotation: dstAnn);
          if (srcEp == null || dstEp == null) continue;

          try {
            final cable = Cable(srcNode: srcNode, srcEndpoint: srcEp, dstNode: dstNode, dstEndpoint: dstEp);
            cables.add(cable);
          } catch (_) {
            // skip invalid
          }
        }
      } catch (e) {
        print("Failed to load patch: $e");
      }
    }
    
    var interface = await UserInterface.load(info);
    return Preset(
      info: info,
      patch: (() {
        final p = Patch();
        p.nodes = nodes;
        p.cables = cables;
        return p;
      })(),
      interface: ValueNotifier(interface),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  static Preset blank(Directory presetDirectory, List<Plugin> plugins, bool uiVisible, AudioManager? audioManager) {
    var info = PresetInfo(
      directory: presetDirectory,
      hasInterface: false,
    );
    return Preset(
      info: info,
      patch: Patch(),
      interface: ValueNotifier(null),
      uiVisible: uiVisible,
      plugins: plugins,
      audioManager: audioManager,
    );
  }

  Future<void> save() async {
    print("Saving preset");
    // Create the preset directory if it doesn't exist
    await info.directory.create(recursive: true);
    
    await info.save();
    
    // Save the patch data
    try {
      final nodesJson = patch.nodes
          .map((n) => jsonDecode(n.toJson()) as Map<String, dynamic>)
          .toList();

      final cablesJson = patch.cables
          .map((c) => {
                'srcNodeId': c.source.node.id,
                'srcAnnotation': c.source.endpoint.annotation,
                'dstNodeId': c.destination.node.id,
                'dstAnnotation': c.destination.endpoint.annotation,
              })
          .toList();

      final jsonStr = jsonEncode({
        'nodes': nodesJson,
        'cables': cablesJson,
      });
      await info.patchFile.writeAsString(jsonStr);
      print("Saved patch file in preset to: ${info.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
    
    await interface.value?.save();
  }

  @override
  Widget build(BuildContext context) {
    return PatchEditor(
      presetInfo: info,
      plugins: plugins,
      patch: patch,
      audioManager: audioManager,
    );
  }
}
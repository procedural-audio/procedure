import 'package:flutter/material.dart';
import 'package:metasampler/bindings/api/patch.dart' as rust_patch;
import 'package:metasampler/bindings/api/node.dart' as rust_node;
import 'package:metasampler/bindings/api/graph.dart' as api;
import 'patch.dart';
import 'node.dart';
import 'pin.dart';
import 'module.dart';
import '../plugin/plugin.dart';
import '../preset/info.dart';

/// Simple patch widget that directly uses PatchEditor with Rust patch
class SimplePatchWidget extends StatefulWidget {
  final PresetInfo info;
  final List<Plugin> plugins;
  
  const SimplePatchWidget({
    Key? key,
    required this.info,
    required this.plugins,
  }) : super(key: key);
  
  @override
  State<SimplePatchWidget> createState() => _SimplePatchWidgetState();
}

class _SimplePatchWidgetState extends State<SimplePatchWidget> {
  late rust_patch.Patch _rustPatch;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    _loadPatch();
  }
  
  Future<void> _loadPatch() async {
    _rustPatch = rust_patch.Patch();
    
    // Try to load existing patch file
    if (await widget.info.patchFile.exists()) {
      try {
        var contents = await widget.info.patchFile.readAsString();
        await _rustPatch.loadFromJson(jsonStr: contents);
      } catch (e) {
        print("Failed to load patch: $e");
      }
    }
    
    setState(() {});
  }
  
  Future<void> _savePatch() async {
    try {
      var jsonStr = await _rustPatch.saveToJson();
      await widget.info.patchFile.writeAsString(jsonStr);
      print("Saved patch file: ${widget.info.patchFile.path}");
    } catch (e) {
      print("Failed to save patch: $e");
    }
  }
  
  // Callback implementations
  void _onAddNode(Module module, Offset position) {
    // Create Rust node and add to patch
    var rustModule = module.toRustModule();
    var rustNode = rust_node.Node.from(
      id: DateTime.now().millisecondsSinceEpoch, // Simple ID generation
      module: rustModule,
      position: (position.dx, position.dy),
    );
    
    if (rustNode != null) {
      _rustPatch.addNode(node: rustNode);
      _savePatch();
      setState(() {}); // Trigger rebuild to show new node
    }
  }
  
  void _onRemoveNode(NodeEditor node) {
    if (node.rustNode != null) {
      _rustPatch.removeNode(node: node.rustNode!);
      _savePatch();
      setState(() {}); // Trigger rebuild
    }
  }
  
  void _onAddCable(Pin start, Pin end) {
    try {
      // Create a temporary graph to generate the cable
      var tempGraph = api.Graph();
      tempGraph.addCable(
        srcNode: start.node.rustNode!,
        srcEndpoint: start.endpoint,
        dstNode: end.node.rustNode!,
        dstEndpoint: end.endpoint,
      );
      
      // Get the created cable from the graph
      var cables = tempGraph.cables;
      if (cables.isNotEmpty) {
        var cable = cables.first;
        _rustPatch.addCable(cable: cable);
        print("Added cable: ${start.node.module.name} -> ${end.node.module.name}");
        _savePatch();
        setState(() {}); // Trigger rebuild to show new cable
      }
    } catch (e) {
      print("Failed to add cable: $e");
    }
  }
  
  void _onRemoveCable(Pin start, Pin end) {
    try {
      // Find the cable to remove by matching endpoints
      var cables = _rustPatch.getCables();
      for (var cable in cables) {
        bool isMatch = false;
        
        // Check if this cable matches the pins (either direction)
        if ((cable.source.node.id == start.node.rustNode!.id &&
             cable.source.endpoint.type == start.endpoint.type &&
             cable.source.endpoint.annotation == start.endpoint.annotation &&
             cable.destination.node.id == end.node.rustNode!.id &&
             cable.destination.endpoint.type == end.endpoint.type &&
             cable.destination.endpoint.annotation == end.endpoint.annotation) ||
            (cable.source.node.id == end.node.rustNode!.id &&
             cable.source.endpoint.type == end.endpoint.type &&
             cable.source.endpoint.annotation == end.endpoint.annotation &&
             cable.destination.node.id == start.node.rustNode!.id &&
             cable.destination.endpoint.type == start.endpoint.type &&
             cable.destination.endpoint.annotation == start.endpoint.annotation)) {
          isMatch = true;
        }
        
        if (isMatch) {
          _rustPatch.removeCable(cable: cable);
          print("Removed cable");
          _savePatch();
          setState(() {}); // Trigger rebuild to hide removed cable
          break;
        }
      }
    } catch (e) {
      print("Failed to remove cable: $e");
    }
  }
  
  void _onBatchRemoveNodes(List<NodeEditor> nodesToRemove) {
    for (var node in nodesToRemove) {
      if (node.rustNode != null) {
        _rustPatch.removeNode(node: node.rustNode!);
      }
    }
    _savePatch();
    setState(() {}); // Trigger rebuild
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PatchEditor(
      rustPatch: _rustPatch,
      plugins: widget.plugins,
      transformationController: _transformationController,
      onAddNode: _onAddNode,
      onRemoveNode: _onRemoveNode,
      onAddCable: _onAddCable,
      onRemoveCable: _onRemoveCable,
      onBatchRemoveNodes: _onBatchRemoveNodes,
    );
  }
}
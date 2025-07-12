import 'package:flutter/material.dart';
import 'patch.dart';
import 'node.dart';
import 'connector.dart';
import 'pin.dart';
import 'module.dart';
import '../plugin/plugin.dart';
import '../preset/info.dart';

// Simple command pattern for undo/redo
abstract class PatchCommand {
  String get description;
  void execute(_PatchManagerWidgetState state);
  void undo(_PatchManagerWidgetState state);
}

class AddNodeCommand extends PatchCommand {
  final Module module;
  final Offset position;
  Node? _addedNode;
  
  AddNodeCommand(this.module, this.position);
  
  @override
  String get description => 'Add ${module.name}';
  
  @override
  void execute(_PatchManagerWidgetState state) {
    _addedNode = Node(
      module: module,
      patch: state._patch,
      onAddConnector: state._onAddConnector,
      onRemoveConnections: state._onRemoveConnections,
      position: position,
      newConnector: state._newConnector,
      onNewConnectorDrag: state._onNewConnectorDrag,
      onNewConnectorSetStart: state._onNewConnectorSetStart,
      onNewConnectorSetEnd: state._onNewConnectorSetEnd,
      onNewConnectorReset: state._onNewConnectorReset,
      onAddNewConnector: state._onAddNewConnector,
    );
    state._updatePatch(nodes: [...state._nodes, _addedNode!]);
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    if (_addedNode != null) {
      final newNodes = state._nodes.where((n) => n != _addedNode).toList();
      final newConnectors = state._connectors
          .where((c) => c.start.node != _addedNode && c.end.node != _addedNode)
          .toList();
      state._updatePatch(nodes: newNodes, connectors: newConnectors);
    }
  }
}

class RemoveNodeCommand extends PatchCommand {
  final Node node;
  final List<Connector> removedConnectors = [];
  
  RemoveNodeCommand(this.node);
  
  @override
  String get description => 'Remove ${node.module.name}';
  
  @override
  void execute(_PatchManagerWidgetState state) {
    // Store connectors that will be removed
    removedConnectors.clear();
    removedConnectors.addAll(
      state._connectors.where((c) => 
        c.start.node == node || c.end.node == node
      )
    );
    
    final newNodes = state._nodes.where((n) => n != node).toList();
    final newConnectors = state._connectors
        .where((c) => c.start.node != node && c.end.node != node)
        .toList();
    state._updatePatch(nodes: newNodes, connectors: newConnectors);
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    final newNodes = [...state._nodes, node];
    final newConnectors = [...state._connectors, ...removedConnectors];
    state._updatePatch(nodes: newNodes, connectors: newConnectors);
  }
}

class AddConnectorCommand extends PatchCommand {
  final Pin start;
  final Pin end;
  Connector? _addedConnector;
  
  AddConnectorCommand(this.start, this.end);
  
  @override
  String get description => 'Connect ${start.node.module.name} to ${end.node.module.name}';
  
  @override
  void execute(_PatchManagerWidgetState state) {
    _addedConnector = Connector(
      start: start,
      end: end,
      patch: state._patch,
    );
    state._updatePatch(connectors: [...state._connectors, _addedConnector!]);
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    if (_addedConnector != null) {
      final newConnectors = state._connectors
          .where((c) => c != _addedConnector)
          .toList();
      state._updatePatch(connectors: newConnectors);
    }
  }
}

class RemoveConnectorCommand extends PatchCommand {
  final Connector connector;
  
  RemoveConnectorCommand(this.connector);
  
  @override
  String get description => 'Disconnect';
  
  @override
  void execute(_PatchManagerWidgetState state) {
    final newConnectors = state._connectors
        .where((c) => c != connector)
        .toList();
    state._updatePatch(connectors: newConnectors);
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    final newConnectors = [...state._connectors, connector];
    state._updatePatch(connectors: newConnectors);
  }
}

class MoveNodeCommand extends PatchCommand {
  final Node node;
  final Offset oldPosition;
  final Offset newPosition;
  
  MoveNodeCommand(this.node, this.oldPosition, this.newPosition);
  
  @override
  String get description => 'Move ${node.module.name}';
  
  @override
  void execute(_PatchManagerWidgetState state) {
    node.position.value = newPosition;
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    node.position.value = oldPosition;
  }
}

class BatchCommand extends PatchCommand {
  final List<PatchCommand> commands;
  final String _description;
  
  BatchCommand(this.commands, this._description);
  
  @override
  String get description => _description;
  
  @override
  void execute(_PatchManagerWidgetState state) {
    for (final command in commands) {
      command.execute(state);
    }
  }
  
  @override
  void undo(_PatchManagerWidgetState state) {
    // Undo in reverse order
    for (final command in commands.reversed) {
      command.undo(state);
    }
  }
}

// Callback types for patch operations
typedef NodeCallback = void Function(Module module, Offset position);
typedef ConnectorCallback = void Function(Pin start, Pin end);
typedef NodeRemoveCallback = void Function(Node node);
typedef NodeMoveCallback = void Function(Node node, Offset oldPosition, Offset newPosition);
typedef ConnectorRemoveCallback = void Function(Connector connector);

class PatchManagerWidget extends StatefulWidget {
  final PresetInfo info;
  final List<Plugin> plugins;
  
  const PatchManagerWidget({
    Key? key,
    required this.info,
    required this.plugins,
  }) : super(key: key);
  
  @override
  State<PatchManagerWidget> createState() => _PatchManagerWidgetState();
}

class _PatchManagerWidgetState extends State<PatchManagerWidget> {
  // Patch data model
  late Patch _patch;
  
  // Nodes and connectors as plain lists
  List<Node> get _nodes => _patch.nodes;
  List<Connector> get _connectors => _patch.connectors;
  
  // NewConnector for handling new connections
  final NewConnector _newConnector = NewConnector();
  
  @override
  void initState() {
    super.initState();
    _loadPatch();
  }
  
  Future<void> _loadPatch() async {
    final loadedPatch = await Patch.load(
      widget.info, 
      widget.plugins,
      newConnector: _newConnector,
      onNewConnectorDrag: _onNewConnectorDrag,
      onNewConnectorSetStart: _onNewConnectorSetStart,
      onNewConnectorSetEnd: _onNewConnectorSetEnd,
      onNewConnectorReset: _onNewConnectorReset,
      onAddNewConnector: _onAddNewConnector,
    );
    if (loadedPatch != null) {
      setState(() {
        _patch = loadedPatch;
      });
    } else {
      // Create new patch if loading fails
      setState(() {
        _patch = Patch(info: widget.info);
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  // Helper method to update patch with new nodes/connectors
  void _updatePatch({List<Node>? nodes, List<Connector>? connectors}) {
    setState(() {
      _patch = Patch(
        info: _patch.info,
        nodes: nodes ?? _patch.nodes,
        connectors: connectors ?? _patch.connectors,
      );
    });
  }
  
  // NewConnector callback methods
  void _onNewConnectorDrag(Offset offset) {
    _newConnector.onDrag(offset);
  }
  
  void _onNewConnectorSetStart(Pin pin) {
    _newConnector.setStart(pin);
  }
  
  void _onNewConnectorSetEnd(Pin? pin) {
    _newConnector.setEnd(pin);
  }
  
  void _onNewConnectorReset() {
    _newConnector.reset();
  }
  
  void _onAddNewConnector() {
    if (_newConnector.start != null && _newConnector.end != null) {
      _onAddConnector(_newConnector.start!, _newConnector.end!);
    }
    _newConnector.reset();
  }
  
  
  // Command history for undo/redo
  final List<PatchCommand> _undoStack = [];
  final List<PatchCommand> _redoStack = [];
  static const int maxHistorySize = 100;
  
  // Callback implementations for PatchEditor
  void _onAddNode(Module module, Offset position) {
    final command = AddNodeCommand(module, position);
    _executeCommand(command);
  }
  
  void _onRemoveNode(Node node) {
    final command = RemoveNodeCommand(node);
    _executeCommand(command);
  }
  
  void _onAddConnector(Pin start, Pin end) {
    final command = AddConnectorCommand(start, end);
    _executeCommand(command);
  }
  
  void _onRemoveConnector(Connector connector) {
    final command = RemoveConnectorCommand(connector);
    _executeCommand(command);
  }
  
  void _onMoveNode(Node node, Offset oldPosition, Offset newPosition) {
    final command = MoveNodeCommand(node, oldPosition, newPosition);
    _executeCommand(command);
  }
  
  void _onBatchRemoveNodes(List<Node> nodesToRemove) {
    if (nodesToRemove.isEmpty) return;
    
    if (nodesToRemove.length == 1) {
      _onRemoveNode(nodesToRemove.first);
    } else {
      final commands = nodesToRemove
          .map((node) => RemoveNodeCommand(node))
          .toList();
      final batchCommand = BatchCommand(
        commands,
        'Remove ${commands.length} nodes'
      );
      _executeCommand(batchCommand);
    }
  }
  
  void _executeCommand(PatchCommand command) {
    // Execute the command
    command.execute(this);
    
    // Add to undo stack
    _undoStack.add(command);
    _redoStack.clear();
    
    // Limit history size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    setState(() {});
  }
  
  // Public methods for undo/redo
  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo(this);
      _redoStack.add(command);
      setState(() {});
    }
  }
  
  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.execute(this);
      _undoStack.add(command);
      setState(() {});
    }
  }
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  // Helper methods
  void _onRemoveConnections(Pin pin) {
    // Find and remove all connectors connected to this pin
    var connectorsToRemove = _connectors
        .where((c) => c.start == pin || c.end == pin)
        .toList();
    
    for (var connector in connectorsToRemove) {
      _onRemoveConnector(connector);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PatchEditor(
      patch: _patch,
      plugins: widget.plugins,
      newConnector: _newConnector,
      
      // Provide callbacks
      onAddNode: _onAddNode,
      onRemoveNode: _onRemoveNode,
      onAddConnector: _onAddConnector,
      onRemoveConnector: _onRemoveConnector,
      onMoveNode: _onMoveNode,
      onBatchRemoveNodes: _onBatchRemoveNodes,
      
      // Provide undo/redo functions
      onUndo: undo,
      onRedo: redo,
    );
  }
}
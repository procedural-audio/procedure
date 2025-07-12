import 'package:flutter/material.dart';
import 'node.dart';
import 'connector.dart';
import 'pin.dart';
import 'module.dart';
import 'patch.dart';

// Base class for all patch commands
abstract class PatchCommand {
  String get description;
  void execute(PatchState state);
  void undo(PatchState state);
}

// Interface for patch state manipulation
abstract class PatchState {
  ValueNotifier<List<Node>> get nodes;
  ValueNotifier<List<Connector>> get connectors;
  ValueNotifier<List<Node>> get selectedNodes;
  Patch get patchWidget;
  
  void updatePlayback();
  void setState(VoidCallback fn);
  void addConnector(Pin start, Pin end);
  void removeConnectionsTo(Pin pin);
}

// Command implementations
class AddNodeCommand extends PatchCommand {
  final Module module;
  final Offset position;
  late Node node;
  
  AddNodeCommand(this.module, this.position);
  
  @override
  String get description => 'Add ${module.name}';
  
  @override
  void execute(PatchState state) {
    // This will be handled by the PatchManagerWidget
    // which will create the node with proper patch widget reference
    throw UnimplementedError('Use PatchManagerWidget callbacks instead');
  }
  
  @override
  void undo(PatchState state) {
    state.nodes.value = state.nodes.value.where((n) => n != node).toList();
    // Remove all connectors connected to this node
    state.connectors.value = state.connectors.value
        .where((c) => c.start.node != node && c.end.node != node)
        .toList();
    state.updatePlayback();
    state.setState(() {});
  }
}

class RemoveNodeCommand extends PatchCommand {
  final Node node;
  final List<Connector> removedConnectors = [];
  
  RemoveNodeCommand(this.node);
  
  @override
  String get description => 'Remove ${node.module.name}';
  
  @override
  void execute(PatchState state) {
    // Store connectors that will be removed
    removedConnectors.clear();
    removedConnectors.addAll(
      state.connectors.value.where((c) => 
        c.start.node == node || c.end.node == node
      )
    );
    
    state.nodes.value = state.nodes.value.where((n) => n != node).toList();
    state.connectors.value = state.connectors.value
        .where((c) => c.start.node != node && c.end.node != node)
        .toList();
    state.updatePlayback();
    state.setState(() {});
  }
  
  @override
  void undo(PatchState state) {
    state.nodes.value = [...state.nodes.value, node];
    state.connectors.value = [...state.connectors.value, ...removedConnectors];
    state.updatePlayback();
    state.setState(() {});
  }
}

class AddConnectorCommand extends PatchCommand {
  final Pin start;
  final Pin end;
  late Connector connector;
  
  AddConnectorCommand(this.start, this.end);
  
  @override
  String get description => 'Connect ${start.node.module.name} to ${end.node.module.name}';
  
  @override
  void execute(PatchState state) {
    connector = Connector(
      start: start,
      end: end,
      patch: state.patchWidget,
    );
    
    state.connectors.value = [...state.connectors.value, connector];
    state.updatePlayback();
    state.setState(() {});
  }
  
  @override
  void undo(PatchState state) {
    state.connectors.value = state.connectors.value
        .where((c) => c != connector)
        .toList();
    state.updatePlayback();
    state.setState(() {});
  }
}

class RemoveConnectorCommand extends PatchCommand {
  final Connector connector;
  
  RemoveConnectorCommand(this.connector);
  
  @override
  String get description => 'Disconnect';
  
  @override
  void execute(PatchState state) {
    state.connectors.value = state.connectors.value
        .where((c) => c != connector)
        .toList();
    state.updatePlayback();
    state.setState(() {});
  }
  
  @override
  void undo(PatchState state) {
    state.connectors.value = [...state.connectors.value, connector];
    state.updatePlayback();
    state.setState(() {});
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
  void execute(PatchState state) {
    node.position.value = newPosition;
    state.setState(() {});
  }
  
  @override
  void undo(PatchState state) {
    node.position.value = oldPosition;
    state.setState(() {});
  }
}

class BatchCommand extends PatchCommand {
  final List<PatchCommand> commands;
  final String _description;
  
  BatchCommand(this.commands, this._description);
  
  @override
  String get description => _description;
  
  @override
  void execute(PatchState state) {
    for (final command in commands) {
      command.execute(state);
    }
  }
  
  @override
  void undo(PatchState state) {
    // Undo in reverse order
    for (final command in commands.reversed) {
      command.undo(state);
    }
  }
}

// The PatchManager class
class PatchManager {
  final List<PatchCommand> _undoStack = [];
  final List<PatchCommand> _redoStack = [];
  
  static const int maxHistorySize = 100;
  
  // Callbacks for UI updates
  VoidCallback? onHistoryChanged;
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  String? get undoDescription => 
      _undoStack.isEmpty ? null : _undoStack.last.description;
  
  String? get redoDescription => 
      _redoStack.isEmpty ? null : _redoStack.last.description;
  
  void executeCommand(PatchCommand command, PatchState state) {
    command.execute(state);
    _undoStack.add(command);
    _redoStack.clear();
    
    // Limit history size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    onHistoryChanged?.call();
  }
  
  void undo(PatchState state) {
    if (!canUndo) return;
    
    final command = _undoStack.removeLast();
    command.undo(state);
    _redoStack.add(command);
    
    onHistoryChanged?.call();
  }
  
  void redo(PatchState state) {
    if (!canRedo) return;
    
    final command = _redoStack.removeLast();
    command.execute(state);
    _undoStack.add(command);
    
    onHistoryChanged?.call();
  }
  
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    onHistoryChanged?.call();
  }
}
import 'package:flutter/material.dart';
import 'package:metasampler/patch/module.dart';
import 'package:metasampler/patch/node.dart';
import 'package:metasampler/patch/connector.dart';
import 'package:metasampler/patch/pin.dart';

/// Base class for all patch editing commands that support undo/redo
abstract class PatchCommand {
  String get description;
  void execute(PatchState patchState);
  void undo(PatchState patchState);
}

/// Interface for patch operations that commands can use
abstract class PatchState {
  // Node operations
  NodeEditor addNodeDirect(Module module, Offset position);
  void removeNodeDirect(NodeEditor node);
  
  // Connector operations
  Connector? addConnectorDirect(Pin start, Pin end);
  void removeConnectorDirect(Connector connector);
  void addConnectorBackDirect(Connector connector);
  
  // Selection operations
  void setSelectionDirect(List<NodeEditor> nodes);
  List<NodeEditor> get currentSelection;
  
  // Access to collections
  List<NodeEditor> get nodes;
  List<Connector> get connectors;
}

/// Commands that can be merged together (like multiple position changes)
abstract class MergeableCommand extends PatchCommand {
  bool canMergeWith(PatchCommand other);
  PatchCommand mergeWith(PatchCommand other);
}

/// Manages the history of patch commands for undo/redo functionality
class PatchHistoryManager {
  final List<PatchCommand> _history = [];
  int _currentIndex = -1;
  final int maxHistorySize;
  
  // Callbacks for UI updates
  VoidCallback? onHistoryChanged;

  PatchHistoryManager({this.maxHistorySize = 100});

  bool get canUndo => _currentIndex >= 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  String? get undoDescription => 
    canUndo ? _history[_currentIndex].description : null;
  
  String? get redoDescription => 
    canRedo ? _history[_currentIndex + 1].description : null;

  void executeCommand(PatchCommand command, PatchState patchState) {
    // Remove any commands after current index (when branching)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Try to merge with previous command if possible
    if (_history.isNotEmpty && 
        _currentIndex >= 0 && 
        command is MergeableCommand) {
      final lastCommand = _history[_currentIndex];
      if (command.canMergeWith(lastCommand)) {
        _history[_currentIndex] = command.mergeWith(lastCommand);
        command.execute(patchState);
        onHistoryChanged?.call();
        return;
      }
    }

    // Execute and add to history
    command.execute(patchState);
    _history.add(command);
    _currentIndex++;

    // Trim history if too large
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }
    
    onHistoryChanged?.call();
  }

  void undo(PatchState patchState) {
    if (canUndo) {
      _history[_currentIndex].undo(patchState);
      _currentIndex--;
      onHistoryChanged?.call();
    }
  }

  void redo(PatchState patchState) {
    if (canRedo) {
      _currentIndex++;
      _history[_currentIndex].execute(patchState);
      onHistoryChanged?.call();
    }
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
    onHistoryChanged?.call();
  }
}

/// Command to add a new node to the patch
class AddNodeCommand extends PatchCommand {
  final Module module;
  final Offset position;
  NodeEditor? _addedNode; // Store reference for undo

  AddNodeCommand(this.module, this.position);

  @override
  String get description => "Add ${module.name}";

  @override
  void execute(PatchState patchState) {
    _addedNode = patchState.addNodeDirect(module, position);
  }

  @override
  void undo(PatchState patchState) {
    if (_addedNode != null) {
      patchState.removeNodeDirect(_addedNode!);
    }
  }
}

/// Command to remove a node from the patch
class RemoveNodeCommand extends PatchCommand {
  final NodeEditor node;
  final Module module;
  final Offset position;
  final List<Connector> _removedConnectors = [];

  RemoveNodeCommand(this.node) : 
    module = node.module,
    position = node.position.value;

  @override
  String get description => "Remove ${node.module.name}";

  @override
  void execute(PatchState patchState) {
    // Store connectors that will be removed
    _removedConnectors.clear();
    for (var connector in patchState.connectors) {
      if (connector.start.node == node || connector.end.node == node) {
        _removedConnectors.add(connector);
      }
    }
    
    patchState.removeNodeDirect(node);
  }

  @override
  void undo(PatchState patchState) {
    // Recreate node instead of reusing the old one
    patchState.addNodeDirect(module, position);
    
    // Note: Connectors cannot be easily restored because they reference the old node
    // For now, don't restore connectors on undo remove
  }
}

/// Command to move a node to a new position
class MoveNodeCommand extends MergeableCommand {
  final NodeEditor node;
  final Offset oldPosition;
  final Offset newPosition;

  MoveNodeCommand(this.node, this.oldPosition, this.newPosition);

  @override
  String get description => "Move ${node.module.name}";

  @override
  void execute(PatchState patchState) {
    node.position.value = newPosition;
  }

  @override
  void undo(PatchState patchState) {
    node.position.value = oldPosition;
  }

  @override
  bool canMergeWith(PatchCommand other) {
    return other is MoveNodeCommand && other.node == node;
  }

  @override
  PatchCommand mergeWith(PatchCommand other) {
    final otherMove = other as MoveNodeCommand;
    return MoveNodeCommand(node, oldPosition, otherMove.newPosition);
  }
}

/// Command to add a connector between two pins
class AddConnectorCommand extends PatchCommand {
  final Pin startPin;
  final Pin endPin;
  Connector? _addedConnector;

  AddConnectorCommand(this.startPin, this.endPin);

  @override
  String get description => "Connect ${startPin.endpoint.annotation} to ${endPin.endpoint.annotation}";

  @override
  void execute(PatchState patchState) {
    _addedConnector = patchState.addConnectorDirect(startPin, endPin);
  }

  @override
  void undo(PatchState patchState) {
    if (_addedConnector != null) {
      patchState.removeConnectorDirect(_addedConnector!);
    }
  }
}

/// Command to remove a connector
class RemoveConnectorCommand extends PatchCommand {
  final Connector connector;

  RemoveConnectorCommand(this.connector);

  @override
  String get description => "Disconnect ${connector.start.endpoint.annotation} from ${connector.end.endpoint.annotation}";

  @override
  void execute(PatchState patchState) {
    patchState.removeConnectorDirect(connector);
  }

  @override
  void undo(PatchState patchState) {
    patchState.addConnectorBackDirect(connector);
  }
}

/// Command to select/deselect nodes
class SelectionCommand extends MergeableCommand {
  final List<NodeEditor> oldSelection;
  final List<NodeEditor> newSelection;

  SelectionCommand(this.oldSelection, this.newSelection);

  @override
  String get description {
    if (newSelection.isEmpty) return "Deselect all";
    if (newSelection.length == 1) return "Select ${newSelection.first.module.name}";
    return "Select ${newSelection.length} nodes";
  }

  @override
  void execute(PatchState patchState) {
    patchState.setSelectionDirect(newSelection);
  }

  @override
  void undo(PatchState patchState) {
    patchState.setSelectionDirect(oldSelection);
  }

  @override
  bool canMergeWith(PatchCommand other) {
    // Only merge if the other command is also a selection command
    // and was executed very recently (to avoid merging distant selections)
    return other is SelectionCommand;
  }

  @override
  PatchCommand mergeWith(PatchCommand other) {
    final otherSelection = other as SelectionCommand;
    return SelectionCommand(oldSelection, otherSelection.newSelection);
  }
}

/// Command to delete multiple selected nodes
class DeleteSelectionCommand extends PatchCommand {
  final List<NodeEditor> deletedNodes;
  final List<(Module, Offset)> nodeData;
  final List<Connector> _removedConnectors = [];

  DeleteSelectionCommand(this.deletedNodes) :
    nodeData = deletedNodes.map((node) => (node.module, node.position.value)).toList();

  @override
  String get description {
    if (deletedNodes.length == 1) {
      return "Delete ${deletedNodes.first.module.name}";
    }
    return "Delete ${deletedNodes.length} nodes";
  }

  @override
  void execute(PatchState patchState) {
    // Store connectors that will be removed
    _removedConnectors.clear();
    for (var connector in patchState.connectors) {
      if (deletedNodes.contains(connector.start.node) || 
          deletedNodes.contains(connector.end.node)) {
        _removedConnectors.add(connector);
      }
    }
    
    // Remove all nodes
    for (var node in deletedNodes) {
      patchState.removeNodeDirect(node);
    }
  }

  @override
  void undo(PatchState patchState) {
    // Recreate nodes from stored data
    for (var (module, position) in nodeData) {
      patchState.addNodeDirect(module, position);
    }
    
    // Note: Connectors cannot be easily restored because they reference old nodes
    // For now, don't restore connectors on undo delete
  }
}

/// Compound command that executes multiple commands as one atomic operation
class CompoundCommand extends PatchCommand {
  final List<PatchCommand> commands;
  final String _description;

  CompoundCommand(this.commands, this._description);

  @override
  String get description => _description;

  @override
  void execute(PatchState patchState) {
    for (var command in commands) {
      command.execute(patchState);
    }
  }

  @override
  void undo(PatchState patchState) {
    // Undo in reverse order
    for (var command in commands.reversed) {
      command.undo(patchState);
    }
  }
}
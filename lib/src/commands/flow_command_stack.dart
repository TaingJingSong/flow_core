import 'dart:async';

import 'flow_command.dart';
import 'flow_document_state.dart';
import 'flow_history_event.dart';

class _HistoryEntry {
  _HistoryEntry(this.command, this.time);
  final FlowCommand command;
  final DateTime time;
}

/// Manages the undo and redo stacks for a [FlowDocumentState].
///
/// - Pushing a command clears the redo stack.
/// - Mergeable commands collapse within [mergeWindow].
/// - Undo stack is capped at [historyLimit]; oldest entries are dropped.
class FlowCommandStack {
  FlowCommandStack({
    required FlowDocumentState state,
    this.historyLimit = 200,
    this.mergeWindow = const Duration(milliseconds: 500),
    DateTime Function()? now,
  })  : _state = state,
        _now = now ?? DateTime.now;

  final FlowDocumentState _state;
  final DateTime Function() _now;

  /// Maximum number of undo entries retained. Oldest are dropped first.
  final int historyLimit;

  /// Two consecutive mergeable commands are merged if their timestamps
  /// differ by at most this duration.
  final Duration mergeWindow;

  final List<_HistoryEntry> _undo = <_HistoryEntry>[];
  final List<_HistoryEntry> _redo = <_HistoryEntry>[];

  final StreamController<FlowHistoryEvent> _events =
      StreamController<FlowHistoryEvent>.broadcast();

  FlowDocumentState get state => _state;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoLength => _undo.length;
  int get redoLength => _redo.length;

  /// Stream of history-change events. Broadcast; safe to listen multiple times.
  Stream<FlowHistoryEvent> get events => _events.stream;

  /// Executes [command] and pushes it onto the undo stack.
  void execute(FlowCommand command) {
    command.execute(_state);
    _redo.clear();

    final ts = _now();
    if (command.isMergeable && _undo.isNotEmpty) {
      final top = _undo.last;
      if (top.command.isMergeable &&
          ts.difference(top.time) <= mergeWindow) {
        final merged = top.command.merge(command);
        if (merged != null) {
          _undo[_undo.length - 1] = _HistoryEntry(merged, ts);
          _emit();
          return;
        }
      }
    }

    _undo.add(_HistoryEntry(command, ts));
    while (_undo.length > historyLimit) {
      _undo.removeAt(0);
    }
    _emit();
  }

  /// Executes several commands as a single atomic unit.
  void executeAll(Iterable<FlowCommand> commands) {
    final list = commands.toList(growable: false);
    if (list.isEmpty) return;
    if (list.length == 1) {
      execute(list.first);
      return;
    }
    execute(BatchCommand(label: 'Batch', commands: list));
  }

  void undo() {
    if (_undo.isEmpty) return;
    final entry = _undo.removeLast();
    entry.command.undo(_state);
    _redo.add(entry);
    _emit();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final entry = _redo.removeLast();
    entry.command.execute(_state);
    _undo.add(entry);
    _emit();
  }

  void clear() {
    if (_undo.isEmpty && _redo.isEmpty) return;
    _undo.clear();
    _redo.clear();
    _emit();
  }

  void dispose() {
    _events.close();
  }

  void _emit() {
    if (_events.isClosed) return;
    _events.add(FlowHistoryEvent(
      canUndo: canUndo,
      canRedo: canRedo,
      undoLength: _undo.length,
      redoLength: _redo.length,
      lastLabel: _undo.isEmpty ? null : _undo.last.command.label,
    ));
  }
}

/// Groups multiple commands into a single undoable unit.
///
/// [execute] runs children in order; [undo] runs them in reverse order.
class BatchCommand extends FlowCommand {
  BatchCommand({required this.label, required this.commands});

  @override
  final String label;

  final List<FlowCommand> commands;

  @override
  void execute(FlowDocumentState state) {
    for (final c in commands) {
      c.execute(state);
    }
  }

  @override
  void undo(FlowDocumentState state) {
    for (final c in commands.reversed) {
      c.undo(state);
    }
  }
}
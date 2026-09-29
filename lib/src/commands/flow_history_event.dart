import 'package:meta/meta.dart';

/// Emitted by [FlowCommandStack] after any change to its history.
@immutable
class FlowHistoryEvent {
  const FlowHistoryEvent({
    required this.canUndo,
    required this.canRedo,
    required this.undoLength,
    required this.redoLength,
    this.lastLabel,
  });

  final bool canUndo;
  final bool canRedo;
  final int undoLength;
  final int redoLength;

  /// Label of the most recently executed command, if any.
  final String? lastLabel;

  @override
  String toString() =>
      'FlowHistoryEvent(undo: $undoLength, redo: $redoLength, '
      'canUndo: $canUndo, canRedo: $canRedo)';
}
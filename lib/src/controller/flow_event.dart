import 'package:meta/meta.dart';

import '../model/flow_document.dart';
import '../model/flow_id.dart';
import '../selection/flow_selection.dart';

/// Base type for every event emitted by `FlowController`.
@immutable
sealed class FlowEvent {
  const FlowEvent();
}

/// The whole document was replaced. Fired on load, reset, and on undo/redo.
class DocumentChanged extends FlowEvent {
  /// The whole document was replaced. Fired on load, reset, and on undo/redo.
  const DocumentChanged(this.document);

  final FlowDocument document;
}

/// A page was modified in place. Fired after every command.
class PageChanged extends FlowEvent {
  const PageChanged(this.pageId, {this.label});

  final FlowId pageId;

  /// Label of the command that caused this change, if any.
  final String? label;
}

/// Selection contents changed.
class SelectionChanged extends FlowEvent {
  const SelectionChanged(this.selection);

  final FlowSelection selection;
}

/// Undo/redo availability or stack depth changed.
class HistoryChanged extends FlowEvent {
  const HistoryChanged({
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
  final String? lastLabel;
}
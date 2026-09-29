import 'flow_document_state.dart';

/// A single reversible mutation against a [FlowDocumentState].
///
/// Commands must be:
///
/// - **Deterministic**: same input → same output.
/// - **Reversible**: `undo` after `execute` restores the exact previous
///   state for the fields the command touched.
/// - **Self-contained**: everything needed for `undo` is captured during
///   `execute`, not passed in later.
abstract class FlowCommand {
  const FlowCommand();

  /// Human-readable label shown in UI (e.g. "Move nodes").
  String get label;

  /// Applies the mutation. Called once on push and again on every redo.
  void execute(FlowDocumentState state);

  /// Reverts the mutation. Must restore exactly the state right before
  /// the most recent [execute].
  void undo(FlowDocumentState state);

  /// Whether this command may collapse with a subsequent command.
  ///
  /// Only return true for continuously emitted commands, e.g. drag moves.
  bool get isMergeable => false;

  /// Attempts to combine this command with [next], returning a new command
  /// that represents both. Return null to refuse merging.
  ///
  /// Only called when [isMergeable] is true on both commands and they are
  /// within the stack's merge window.
  FlowCommand? merge(FlowCommand next) => null;
}
import 'flow_layout_input.dart';
import 'flow_layout_result.dart';

/// Computes positions for a set of nodes.
///
/// Implementations must be:
///
/// - **Pure.** Same input → same output. No randomness without a seeded
///   generator, no global state.
/// - **Total.** Unknown edges (referencing missing nodes) are ignored.
/// - **Stable.** When [FlowLayoutInput.pinnedRects] contains a node, its
///   rect is preserved exactly.
abstract class FlowLayoutEngine {
  const FlowLayoutEngine();

  /// Stable identifier used by [FlowLayoutRegistry].
  String get id;

  /// Human-readable name for UI.
  String get name;

  /// Computes positions for [input].
  FlowLayoutResult layout(FlowLayoutInput input);
}
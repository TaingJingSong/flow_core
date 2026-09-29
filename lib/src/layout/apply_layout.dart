import 'package:flow_core/src/layout/flow_layout_direction.dart';

import '../geometry/flow_rect.dart';
import '../model/flow_id.dart';
import '../model/flow_page.dart';
import 'flow_layout_engine.dart';
import 'flow_layout_input.dart';
import 'flow_layout_result.dart';

/// Runs [engine] against [page] and returns the resulting rects.
///
/// This is a pure function; it does not touch the controller. Feed the
/// result into the controller to apply it.
FlowLayoutResult computeLayout(
  FlowPage page,
  FlowLayoutEngine engine, {
  FlowLayoutDirection direction = FlowLayoutDirection.topToBottom,
  FlowLayoutSpacing spacing = const FlowLayoutSpacing(),
  Map<FlowId, FlowRect> pinnedRects = const <FlowId, FlowRect>{},
}) {
  final input = layoutInputFromPage(
    page,
    direction: direction,
    spacing: spacing,
    pinnedRects: pinnedRects,
  );
  return engine.layout(input);
}
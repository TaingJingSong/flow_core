import 'dart:math' as math;

import '../../geometry/flow_point.dart';
import '../../geometry/flow_rect.dart';
import '../../model/flow_id.dart';
import '../flow_layout_engine.dart';
import '../flow_layout_input.dart';
import '../flow_layout_result.dart';

/// Places nodes on a single circle, evenly spaced.
///
/// Useful for star-shaped or unstructured graphs.
class CircularLayout extends FlowLayoutEngine {
  const CircularLayout({this.radius});

  /// Fixed radius. When null, derived from the number of nodes and sizes.
  final double? radius;

  @override
  String get id => 'circular';

  @override
  String get name => 'Circular';

  @override
  FlowLayoutResult layout(FlowLayoutInput input) {
    if (input.nodes.isEmpty) return FlowLayoutResult(<FlowId, FlowRect>{});

    final n = input.nodes.length;
    if (n == 1) {
      final node = input.nodes.first;
      return FlowLayoutResult(<FlowId, FlowRect>{
        node.id: FlowRect.fromLTWH(
          input.spacing.padding,
          input.spacing.padding,
          node.size.width,
          node.size.height,
        ),
      });
    }

    // Effective radius: user-specified, or auto-derived.
    final r = radius ?? _autoRadius(input);

    final center = FlowPoint(
      input.spacing.padding + r,
      input.spacing.padding + r,
    );

    final rects = <FlowId, FlowRect>{};
    for (var i = 0; i < n; i++) {
      final angle = (2 * math.pi * i) / n - math.pi / 2;
      final node = input.nodes[i];
      final cx = center.x + r * math.cos(angle);
      final cy = center.y + r * math.sin(angle);
      rects[node.id] = FlowRect.fromLTWH(
        cx - node.size.width / 2,
        cy - node.size.height / 2,
        node.size.width,
        node.size.height,
      );
    }
    for (final entry in input.pinnedRects.entries) {
      rects[entry.key] = entry.value;
    }
    return FlowLayoutResult(rects);
  }

  double _autoRadius(FlowLayoutInput input) {
    var maxDiagonal = 0.0;
    for (final n in input.nodes) {
      final d = n.size.diagonal;
      if (d > maxDiagonal) maxDiagonal = d;
    }
    final needed = (input.nodes.length * maxDiagonal) / (2 * math.pi);
    return math.max(needed, maxDiagonal);
  }
}
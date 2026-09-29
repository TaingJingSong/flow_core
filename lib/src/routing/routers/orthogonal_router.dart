import 'dart:math' as math;

import '../../geometry/flow_point.dart';
import '../../model/flow_port.dart';
import '../flow_edge_router.dart';
import '../flow_path.dart';
import '../flow_routing_context.dart';

/// Routes edges with axis-aligned segments.
///
/// - When the edge has explicit waypoints, they are used verbatim as a
///   polyline.
/// - Otherwise the path leaves the source in the direction of
///   [FlowRoutingContext.sourceSide], enters the target along
///   [FlowRoutingContext.targetSide], and meets in the middle with a
///   Z-shape (parallel sides) or an L-shape (perpendicular sides).
class OrthogonalRouter extends FlowEdgeRouter {
  const OrthogonalRouter();

  @override
  String get id => 'orthogonal';

  @override
  String get name => 'Orthogonal';

  @override
  FlowPath route(FlowRoutingContext context) {
    if (context.edge.waypoints.isNotEmpty) {
      return FlowPath(
        points: _cleanup(<FlowPoint>[
          context.sourceAnchor,
          ...context.edge.waypoints,
          context.targetAnchor,
        ]),
      );
    }

    final s = context.sourceAnchor;
    final t = context.targetAnchor;
    final pad = context.portPadding;

    final sDir = _directionOf(context.sourceSide, s, t);
    final tDir = _directionOf(context.targetSide, t, s);

    final sExit = FlowPoint(s.x + sDir.x * pad, s.y + sDir.y * pad);
    final tExit = FlowPoint(t.x + tDir.x * pad, t.y + tDir.y * pad);

    final points = <FlowPoint>[s, sExit];

    final sHoriz = sDir.x != 0;
    final tHoriz = tDir.x != 0;

    if (sHoriz && tHoriz) {
      final midX = (sExit.x + tExit.x) / 2;
      points.add(FlowPoint(midX, sExit.y));
      points.add(FlowPoint(midX, tExit.y));
    } else if (!sHoriz && !tHoriz) {
      final midY = (sExit.y + tExit.y) / 2;
      points.add(FlowPoint(sExit.x, midY));
      points.add(FlowPoint(tExit.x, midY));
    } else if (sHoriz) {
      points.add(FlowPoint(tExit.x, sExit.y));
    } else {
      points.add(FlowPoint(sExit.x, tExit.y));
    }

    points.add(tExit);
    points.add(t);

    return FlowPath(points: _cleanup(points));
  }

  static FlowPoint _directionOf(FlowPortSide side, FlowPoint from, FlowPoint toward) {
    switch (side) {
      case FlowPortSide.left:
        return const FlowPoint(-1, 0);
      case FlowPortSide.right:
        return const FlowPoint(1, 0);
      case FlowPortSide.top:
        return const FlowPoint(0, -1);
      case FlowPortSide.bottom:
        return const FlowPoint(0, 1);
      case FlowPortSide.center:
        final dx = toward.x - from.x;
        final dy = toward.y - from.y;
        if (dx == 0 && dy == 0) return const FlowPoint(1, 0);
        return (dx.abs() >= dy.abs())
            ? FlowPoint(dx >= 0 ? 1 : -1, 0)
            : FlowPoint(0, dy >= 0 ? 1 : -1);
    }
  }

  static List<FlowPoint> _cleanup(List<FlowPoint> pts) {
    if (pts.isEmpty) return pts;

    final deduped = <FlowPoint>[];
    for (final p in pts) {
      if (deduped.isEmpty || deduped.last != p) deduped.add(p);
    }
    if (deduped.length < 3) return deduped;

    final out = <FlowPoint>[deduped.first];
    for (var i = 1; i < deduped.length - 1; i++) {
      final a = out.last;
      final b = deduped[i];
      final c = deduped[i + 1];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (cross.abs() > 1e-6) out.add(b);
    }
    out.add(deduped.last);
    return out;
  }
}

// Keep math import used even when assertions disabled.
// ignore: unused_element
final _ = math.pi;
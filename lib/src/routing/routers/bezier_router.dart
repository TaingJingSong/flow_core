import '../../geometry/flow_point.dart';
import '../../model/flow_port.dart';
import '../flow_edge_router.dart';
import '../flow_path.dart';
import '../flow_routing_context.dart';

/// Routes edges as a single cubic bezier from source anchor to target anchor.
///
/// Control points extend outward along the exit directions of each side.
/// When a side is `center`, the direction is taken from the vector between
/// the anchors.
///
/// Edges with explicit waypoints fall back to a straight polyline through
/// them, since cubics cannot faithfully represent user-set vertices.
class BezierRouter extends FlowEdgeRouter {
  const BezierRouter({this.controlRatio = 0.4, this.minControl = 30, this.maxControl = 240});

  /// Fraction of the anchor-to-anchor distance used for control arms.
  final double controlRatio;
  final double minControl;
  final double maxControl;

  @override
  String get id => 'bezier';

  @override
  String get name => 'Bezier';

  @override
  FlowPath route(FlowRoutingContext context) {
    if (context.edge.waypoints.isNotEmpty) {
      return FlowPath(points: <FlowPoint>[
        context.sourceAnchor,
        ...context.edge.waypoints,
        context.targetAnchor,
      ]);
    }

    final s = context.sourceAnchor;
    final t = context.targetAnchor;
    final sDir = _directionOf(context.sourceSide, s, t);
    final tDir = _directionOf(context.targetSide, t, s);

    final distance = s.distanceTo(t);
    final arm = (distance * controlRatio).clamp(minControl, maxControl);

    final c1 = FlowPoint(s.x + sDir.x * arm, s.y + sDir.y * arm);
    final c2 = FlowPoint(t.x + tDir.x * arm, t.y + tDir.y * arm);

    final cubic = FlowCubic(s, c1, c2, t);
    final polyline = cubic.flatten(24);

    return FlowPath(points: polyline, cubics: <FlowCubic>[cubic]);
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
        final m = FlowPoint(dx, dy).magnitude;
        if (m == 0) return const FlowPoint(1, 0);
        return FlowPoint(dx / m, dy / m);
    }
  }
}
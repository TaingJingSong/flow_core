import '../../geometry/flow_point.dart';
import '../flow_edge_router.dart';
import '../flow_path.dart';
import '../flow_routing_context.dart';

/// Draws a direct polyline from source anchor to target anchor.
///
/// When the edge has waypoints, they are inserted in order, producing
/// a straight polyline through them.
class StraightRouter extends FlowEdgeRouter {
  const StraightRouter();

  @override
  String get id => 'straight';

  @override
  String get name => 'Straight';

  @override
  FlowPath route(FlowRoutingContext context) {
    final s = context.sourceAnchor;
    final t = context.targetAnchor;
    final waypoints = context.edge.waypoints;

    if (waypoints.isEmpty) {
      return FlowPath(points: <FlowPoint>[s, t]);
    }
    return FlowPath(points: <FlowPoint>[s, ...waypoints, t]);
  }
}
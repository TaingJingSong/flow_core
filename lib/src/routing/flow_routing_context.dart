import 'package:meta/meta.dart';

import '../geometry/flow_point.dart';
import '../geometry/flow_rect.dart';
import '../model/flow_edge.dart';
import '../model/flow_node.dart';
import '../model/flow_port.dart';

/// Everything a router needs to compute a path for one edge.
@immutable
class FlowRoutingContext {
  const FlowRoutingContext({
    required this.edge,
    required this.source,
    required this.target,
    required this.sourceAnchor,
    required this.targetAnchor,
    required this.sourceSide,
    required this.targetSide,
    this.obstacles = const <FlowRect>[],
    this.portPadding = 20.0,
  });

  final FlowEdge edge;
  final FlowNode source;
  final FlowNode target;

  final FlowPoint sourceAnchor;
  final FlowPoint targetAnchor;

  final FlowPortSide sourceSide;
  final FlowPortSide targetSide;

  /// Bounding boxes of other nodes on the page, for obstacle avoidance.
  final List<FlowRect> obstacles;

  /// Distance (in logical pixels) an orthogonal router leaves the node
  /// before turning. Larger values produce cleaner paths.
  final double portPadding;

  FlowPoint get sourceCenter => source.rect.center;
  FlowPoint get targetCenter => target.rect.center;
}
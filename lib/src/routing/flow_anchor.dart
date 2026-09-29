import 'package:meta/meta.dart';

import '../geometry/flow_point.dart';
import '../model/flow_port.dart';

/// An anchor point on a node plus the side of the node it lies on.
///
/// When a node has no explicit port, the router auto-anchors to the nearest
/// boundary, and [side] records which side was chosen so the router can
/// pick the correct exit direction.
@immutable
class FlowAnchor {
  const FlowAnchor(this.position, this.side);

  final FlowPoint position;
  final FlowPortSide side;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowAnchor && other.position == position && other.side == side;

  @override
  int get hashCode => Object.hash(position, side);

  @override
  String toString() => 'FlowAnchor($position, $side)';
}
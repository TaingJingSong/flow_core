import 'package:meta/meta.dart';

import '../geometry/flow_point.dart';
import '../model/flow_edge.dart';
import '../model/flow_id.dart';
import '../model/flow_node.dart';

/// A port that was hit, along with its absolute position.
@immutable
class FlowPortHit {
  const FlowPortHit({
    required this.nodeId,
    required this.portName,
    required this.position,
  });

  final FlowId nodeId;
  final String portName;
  final FlowPoint position;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowPortHit &&
          other.nodeId == nodeId &&
          other.portName == portName &&
          other.position == position;

  @override
  int get hashCode => Object.hash(nodeId, portName, position);

  @override
  String toString() => 'FlowPortHit($nodeId.$portName)';
}

/// The result of a hit test.
///
/// `nodes` is ordered topmost first (highest z-index, then most recently
/// added). `edges` is ordered by proximity to the query point when
/// available, otherwise by bounding-box size ascending.
@immutable
class FlowHitResult {
  const FlowHitResult({
    this.nodes = const <FlowNode>[],
    this.edges = const <FlowEdge>[],
    this.ports = const <FlowPortHit>[],
  });

  static const FlowHitResult empty = FlowHitResult();

  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final List<FlowPortHit> ports;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty && ports.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Topmost node, or null.
  FlowNode? get topNode => nodes.isEmpty ? null : nodes.first;

  /// Closest edge, or null.
  FlowEdge? get topEdge => edges.isEmpty ? null : edges.first;

  /// Closest port, or null.
  FlowPortHit? get topPort => ports.isEmpty ? null : ports.first;

  @override
  String toString() =>
      'FlowHitResult(nodes: ${nodes.length}, edges: ${edges.length}, '
      'ports: ${ports.length})';
}
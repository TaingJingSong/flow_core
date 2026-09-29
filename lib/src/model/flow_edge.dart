import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../geometry/flow_point.dart';
import 'flow_arrow_head.dart';
import 'flow_edge_kind.dart';
import 'flow_id.dart';
import 'flow_label.dart';
import 'flow_style.dart';

const _listEq = ListEquality<FlowPoint>();
const _mapEq = MapEquality<String, String>();
const _deepEq = DeepCollectionEquality();

/// How an edge is routed between its endpoints.
enum FlowEdgeRouting {
  /// Straight line from source to target.
  straight,

  /// Piecewise orthogonal (Manhattan) path.
  orthogonal,

  /// Cubic bezier curve.
  bezier,

  /// Quadratic curve.
  quadratic,

  /// Orthogonal with obstacle avoidance (requires a router).
  obstacleAvoiding,

  /// Custom path defined by [FlowEdge.waypoints] verbatim.
  custom,
}

/// A connection between two nodes, optionally anchored to named ports.
@immutable
class FlowEdge {
  const FlowEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourcePortName,
    this.targetPortName,
    this.kind = FlowEdgeKind.flow,
    this.routing = FlowEdgeRouting.straight,
    this.waypoints = const <FlowPoint>[],
    this.sourceArrow = FlowArrowHead.none,
    this.targetArrow = FlowArrowHead.filledArrow,
    this.style = FlowStyle.defaults,
    this.label,
    this.data = const <String, Object?>{},
    this.meta = const <String, String>{},
    this.namespace,
    this.zIndex = 0,
    this.locked = false,
    this.visible = true,
  });

  final FlowId id;
  final FlowId sourceNodeId;
  final FlowId targetNodeId;

  /// Port [FlowPort.name] on the source node, or null for node center.
  final String? sourcePortName;

  /// Port [FlowPort.name] on the target node, or null for node center.
  final String? targetPortName;

  final FlowEdgeKind kind;
  final FlowEdgeRouting routing;

  /// Intermediate points the renderer must pass through, in order.
  /// Ignored when [routing] is [FlowEdgeRouting.custom] and
  /// `data['path']` is set instead.
  final List<FlowPoint> waypoints;

  final FlowArrowHead sourceArrow;
  final FlowArrowHead targetArrow;

  final FlowStyle style;
  final FlowLabel? label;

  /// Free-form payload for renderers, plugins, and format round-trips.
  final Map<String, Object?> data;

  /// Small string key-values for annotations.
  final Map<String, String> meta;

  /// Diagram module / subgraph namespace, if any.
  final String? namespace;

  final int zIndex;
  final bool locked;
  final bool visible;

  bool connects(FlowId nodeId) =>
      nodeId == sourceNodeId || nodeId == targetNodeId;

  FlowEdge copyWith({
    FlowId? id,
    FlowId? sourceNodeId,
    FlowId? targetNodeId,
    Object? sourcePortName = _unset,
    Object? targetPortName = _unset,
    FlowEdgeKind? kind,
    FlowEdgeRouting? routing,
    List<FlowPoint>? waypoints,
    FlowArrowHead? sourceArrow,
    FlowArrowHead? targetArrow,
    FlowStyle? style,
    Object? label = _unset,
    Map<String, Object?>? data,
    Map<String, String>? meta,
    Object? namespace = _unset,
    int? zIndex,
    bool? locked,
    bool? visible,
  }) =>
      FlowEdge(
        id: id ?? this.id,
        sourceNodeId: sourceNodeId ?? this.sourceNodeId,
        targetNodeId: targetNodeId ?? this.targetNodeId,
        sourcePortName: sourcePortName == _unset
            ? this.sourcePortName
            : sourcePortName as String?,
        targetPortName: targetPortName == _unset
            ? this.targetPortName
            : targetPortName as String?,
        kind: kind ?? this.kind,
        routing: routing ?? this.routing,
        waypoints: waypoints ?? this.waypoints,
        sourceArrow: sourceArrow ?? this.sourceArrow,
        targetArrow: targetArrow ?? this.targetArrow,
        style: style ?? this.style,
        label: label == _unset ? this.label : label as FlowLabel?,
        data: data ?? this.data,
        meta: meta ?? this.meta,
        namespace:
            namespace == _unset ? this.namespace : namespace as String?,
        zIndex: zIndex ?? this.zIndex,
        locked: locked ?? this.locked,
        visible: visible ?? this.visible,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowEdge &&
          other.id == id &&
          other.sourceNodeId == sourceNodeId &&
          other.targetNodeId == targetNodeId &&
          other.sourcePortName == sourcePortName &&
          other.targetPortName == targetPortName &&
          other.kind == kind &&
          other.routing == routing &&
          _listEq.equals(other.waypoints, waypoints) &&
          other.sourceArrow == sourceArrow &&
          other.targetArrow == targetArrow &&
          other.style == style &&
          other.label == label &&
          _deepEq.equals(other.data, data) &&
          _mapEq.equals(other.meta, meta) &&
          other.namespace == namespace &&
          other.zIndex == zIndex &&
          other.locked == locked &&
          other.visible == visible;

  @override
  int get hashCode => Object.hash(
        id,
        sourceNodeId,
        targetNodeId,
        sourcePortName,
        targetPortName,
        kind,
        routing,
        _listEq.hash(waypoints),
        sourceArrow,
        targetArrow,
        style,
        label,
        _deepEq.hash(data),
        _mapEq.hash(meta),
        namespace,
        zIndex,
        locked,
        visible,
      );

  @override
  String toString() =>
      'FlowEdge($id, $sourceNodeId -> $targetNodeId, $kind)';
}

const Object _unset = Object();
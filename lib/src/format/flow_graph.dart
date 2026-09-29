import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../geometry/flow_rect.dart';
import '../layout/flow_layout_direction.dart';
import '../model/flow_arrow_head.dart';
import '../model/flow_edge_kind.dart';

const _deepEq = DeepCollectionEquality();
const _mapEq = MapEquality<String, String>();

/// Semantic graph — the intermediate representation every parser produces.
///
/// Positions may be present ([FlowGraphNode.rect] non-null) when the source
/// format carries them (draw.io XML). They are absent for text formats
/// (Mermaid, DOT), in which case the import pipeline runs a layout.
@immutable
class FlowGraph {
  FlowGraph({
    Map<String, FlowGraphNode>? nodes,
    Map<String, FlowGraphEdge>? edges,
    Map<String, FlowGraphGroup>? groups,
    this.suggestedDirection = FlowLayoutDirection.topToBottom,
    this.suggestedLayout = 'layered',
    Map<String, Object?>? meta,
  })  : nodes = Map.unmodifiable(nodes ?? const {}),
        edges = Map.unmodifiable(edges ?? const {}),
        groups = Map.unmodifiable(groups ?? const {}),
        meta = Map.unmodifiable(meta ?? const {});

  final Map<String, FlowGraphNode> nodes;
  final Map<String, FlowGraphEdge> edges;
  final Map<String, FlowGraphGroup> groups;

  /// Direction hint from the source (`flowchart TD` → `topToBottom`).
  final FlowLayoutDirection suggestedDirection;

  /// Layout engine id hint (`layered`, `tree`, `grid`, `circular`).
  final String suggestedLayout;

  final Map<String, Object?> meta;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty && groups.isEmpty;

  FlowGraph copyWith({
    Map<String, FlowGraphNode>? nodes,
    Map<String, FlowGraphEdge>? edges,
    Map<String, FlowGraphGroup>? groups,
    FlowLayoutDirection? suggestedDirection,
    String? suggestedLayout,
    Map<String, Object?>? meta,
  }) =>
      FlowGraph(
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
        groups: groups ?? this.groups,
        suggestedDirection: suggestedDirection ?? this.suggestedDirection,
        suggestedLayout: suggestedLayout ?? this.suggestedLayout,
        meta: meta ?? this.meta,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowGraph &&
          const MapEquality<String, FlowGraphNode>().equals(other.nodes, nodes) &&
          const MapEquality<String, FlowGraphEdge>().equals(other.edges, edges) &&
          const MapEquality<String, FlowGraphGroup>().equals(other.groups, groups) &&
          other.suggestedDirection == suggestedDirection &&
          other.suggestedLayout == suggestedLayout &&
          _deepEq.equals(other.meta, meta);

  @override
  int get hashCode => Object.hash(
        const MapEquality<String, FlowGraphNode>().hash(nodes),
        const MapEquality<String, FlowGraphEdge>().hash(edges),
        const MapEquality<String, FlowGraphGroup>().hash(groups),
        suggestedDirection,
        suggestedLayout,
        _deepEq.hash(meta),
      );

  @override
  String toString() =>
      'FlowGraph(nodes: ${nodes.length}, edges: ${edges.length}, '
      'groups: ${groups.length})';
}

@immutable
class FlowGraphNode {
  const FlowGraphNode({
    required this.id,
    this.label = '',
    this.shape = 'rectangle',
    this.groupId,
    this.rect,
    this.tags = const <String>{},
    this.meta = const <String, String>{},
    this.data = const <String, Object?>{},
  });

  final String id;
  final String label;

  /// Semantic type. See the schema doc for the recommended set.
  final String shape;

  final String? groupId;

  /// Present when the source format carries explicit positions.
  final FlowRect? rect;

  final Set<String> tags;
  final Map<String, String> meta;
  final Map<String, Object?> data;

  FlowGraphNode copyWith({
    String? id,
    String? label,
    String? shape,
    Object? groupId = _unset,
    Object? rect = _unset,
    Set<String>? tags,
    Map<String, String>? meta,
    Map<String, Object?>? data,
  }) =>
      FlowGraphNode(
        id: id ?? this.id,
        label: label ?? this.label,
        shape: shape ?? this.shape,
        groupId: groupId == _unset ? this.groupId : groupId as String?,
        rect: rect == _unset ? this.rect : rect as FlowRect?,
        tags: tags ?? this.tags,
        meta: meta ?? this.meta,
        data: data ?? this.data,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowGraphNode &&
          other.id == id &&
          other.label == label &&
          other.shape == shape &&
          other.groupId == groupId &&
          other.rect == rect &&
          const SetEquality<String>().equals(other.tags, tags) &&
          _mapEq.equals(other.meta, meta) &&
          _deepEq.equals(other.data, data);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        shape,
        groupId,
        rect,
        const SetEquality<String>().hash(tags),
        _mapEq.hash(meta),
        _deepEq.hash(data),
      );
}

@immutable
class FlowGraphEdge {
  const FlowGraphEdge({
    required this.id,
    required this.source,
    required this.target,
    this.sourcePort,
    this.targetPort,
    this.label = '',
    this.kind = FlowEdgeKind.flow,
    this.sourceArrow = FlowArrowHead.none,
    this.targetArrow = FlowArrowHead.filledArrow,
    this.dashed = false,
    this.thick = false,
    this.meta = const <String, String>{},
    this.data = const <String, Object?>{},
  });

  final String id;
  final String source;
  final String target;
  final String? sourcePort;
  final String? targetPort;
  final String label;
  final FlowEdgeKind kind;
  final FlowArrowHead sourceArrow;
  final FlowArrowHead targetArrow;
  final bool dashed;
  final bool thick;
  final Map<String, String> meta;
  final Map<String, Object?> data;

  FlowGraphEdge copyWith({
    String? id,
    String? source,
    String? target,
    Object? sourcePort = _unset,
    Object? targetPort = _unset,
    String? label,
    FlowEdgeKind? kind,
    FlowArrowHead? sourceArrow,
    FlowArrowHead? targetArrow,
    bool? dashed,
    bool? thick,
    Map<String, String>? meta,
    Map<String, Object?>? data,
  }) =>
      FlowGraphEdge(
        id: id ?? this.id,
        source: source ?? this.source,
        target: target ?? this.target,
        sourcePort:
            sourcePort == _unset ? this.sourcePort : sourcePort as String?,
        targetPort:
            targetPort == _unset ? this.targetPort : targetPort as String?,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        sourceArrow: sourceArrow ?? this.sourceArrow,
        targetArrow: targetArrow ?? this.targetArrow,
        dashed: dashed ?? this.dashed,
        thick: thick ?? this.thick,
        meta: meta ?? this.meta,
        data: data ?? this.data,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowGraphEdge &&
          other.id == id &&
          other.source == source &&
          other.target == target &&
          other.sourcePort == sourcePort &&
          other.targetPort == targetPort &&
          other.label == label &&
          other.kind == kind &&
          other.sourceArrow == sourceArrow &&
          other.targetArrow == targetArrow &&
          other.dashed == dashed &&
          other.thick == thick &&
          _mapEq.equals(other.meta, meta) &&
          _deepEq.equals(other.data, data);

  @override
  int get hashCode => Object.hash(
        id,
        source,
        target,
        sourcePort,
        targetPort,
        label,
        kind,
        sourceArrow,
        targetArrow,
        dashed,
        thick,
        _mapEq.hash(meta),
        _deepEq.hash(data),
      );
}

@immutable
class FlowGraphGroup {
  const FlowGraphGroup({
    required this.id,
    this.label = '',
    this.parentId,
    this.nodeIds = const <String>[],
    this.childGroupIds = const <String>[],
    this.meta = const <String, String>{},
  });

  final String id;
  final String label;
  final String? parentId;
  final List<String> nodeIds;
  final List<String> childGroupIds;
  final Map<String, String> meta;

  FlowGraphGroup copyWith({
    String? id,
    String? label,
    Object? parentId = _unset,
    List<String>? nodeIds,
    List<String>? childGroupIds,
    Map<String, String>? meta,
  }) =>
      FlowGraphGroup(
        id: id ?? this.id,
        label: label ?? this.label,
        parentId: parentId == _unset ? this.parentId : parentId as String?,
        nodeIds: nodeIds ?? this.nodeIds,
        childGroupIds: childGroupIds ?? this.childGroupIds,
        meta: meta ?? this.meta,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowGraphGroup &&
          other.id == id &&
          other.label == label &&
          other.parentId == parentId &&
          const ListEquality<String>().equals(other.nodeIds, nodeIds) &&
          const ListEquality<String>()
              .equals(other.childGroupIds, childGroupIds) &&
          _mapEq.equals(other.meta, meta);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        parentId,
        const ListEquality<String>().hash(nodeIds),
        const ListEquality<String>().hash(childGroupIds),
        _mapEq.hash(meta),
      );
}

const Object _unset = Object();
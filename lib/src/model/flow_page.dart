import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../geometry/flow_rect.dart';
import 'flow_edge.dart';
import 'flow_group.dart';
import 'flow_id.dart';
import 'flow_layer.dart';
import 'flow_node.dart';

const _mapEq = MapEquality<String, String>();

/// A single canvas within a document. A document may have many pages.
///
/// Entities live in `Map<FlowId, ...>` keyed by their own id for O(1)
/// lookup. Never mutate these maps; treat them as immutable.
@immutable
class FlowPage {
  FlowPage({
    required this.id,
    required this.name,
    Map<FlowId, FlowNode>? nodes,
    Map<FlowId, FlowEdge>? edges,
    Map<FlowId, FlowGroup>? groups,
    Map<FlowId, FlowLayer>? layers,
    this.bounds,
    this.meta = const <String, String>{},
  })  : nodes = Map.unmodifiable(nodes ?? const <FlowId, FlowNode>{}),
        edges = Map.unmodifiable(edges ?? const <FlowId, FlowEdge>{}),
        groups = Map.unmodifiable(groups ?? const <FlowId, FlowGroup>{}),
        layers = Map.unmodifiable(layers ?? const <FlowId, FlowLayer>{});

  factory FlowPage.empty({required FlowId id, String name = 'Page 1'}) {
    final defaultLayer = FlowLayer(id: const FlowId('default'), name: 'Default');
    return FlowPage(
      id: id,
      name: name,
      layers: {defaultLayer.id: defaultLayer},
    );
  }

  final FlowId id;
  final String name;

  final Map<FlowId, FlowNode> nodes;
  final Map<FlowId, FlowEdge> edges;
  final Map<FlowId, FlowGroup> groups;
  final Map<FlowId, FlowLayer> layers;

  /// Optional canvas size hint. Null means infinite / auto.
  final FlowRect? bounds;

  final Map<String, String> meta;

  bool get isEmpty =>
      nodes.isEmpty && edges.isEmpty && groups.isEmpty;

  FlowPage copyWith({
    FlowId? id,
    String? name,
    Map<FlowId, FlowNode>? nodes,
    Map<FlowId, FlowEdge>? edges,
    Map<FlowId, FlowGroup>? groups,
    Map<FlowId, FlowLayer>? layers,
    Object? bounds = _unset,
    Map<String, String>? meta,
  }) =>
      FlowPage(
        id: id ?? this.id,
        name: name ?? this.name,
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
        groups: groups ?? this.groups,
        layers: layers ?? this.layers,
        bounds: bounds == _unset ? this.bounds : bounds as FlowRect?,
        meta: meta ?? this.meta,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowPage &&
          other.id == id &&
          other.name == name &&
          const MapEquality<FlowId, FlowNode>().equals(other.nodes, nodes) &&
          const MapEquality<FlowId, FlowEdge>().equals(other.edges, edges) &&
          const MapEquality<FlowId, FlowGroup>().equals(other.groups, groups) &&
          const MapEquality<FlowId, FlowLayer>().equals(other.layers, layers) &&
          other.bounds == bounds &&
          _mapEq.equals(other.meta, meta);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        const MapEquality<FlowId, FlowNode>().hash(nodes),
        const MapEquality<FlowId, FlowEdge>().hash(edges),
        const MapEquality<FlowId, FlowGroup>().hash(groups),
        const MapEquality<FlowId, FlowLayer>().hash(layers),
        bounds,
        _mapEq.hash(meta),
      );

  @override
  String toString() =>
      'FlowPage($id, "$name", nodes: ${nodes.length}, edges: ${edges.length})';
}

const Object _unset = Object();
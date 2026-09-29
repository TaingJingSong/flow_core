import 'package:meta/meta.dart';

import '../geometry/flow_rect.dart';
import '../geometry/flow_size.dart';
import '../model/flow_edge.dart';
import '../model/flow_id.dart';
import '../model/flow_node.dart';
import '../model/flow_page.dart';
import 'flow_layout_direction.dart';

/// A node fed into a layout engine. Only the fields a layout needs.
@immutable
class FlowLayoutNode {
  const FlowLayoutNode({
    required this.id,
    required this.size,
    this.currentRect,
  });

  final FlowId id;
  final FlowSize size;

  /// Optional starting rect. Engines may use this for stability.
  final FlowRect? currentRect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowLayoutNode &&
          other.id == id &&
          other.size == size &&
          other.currentRect == currentRect;

  @override
  int get hashCode => Object.hash(id, size, currentRect);
}

/// An edge fed into a layout engine.
@immutable
class FlowLayoutEdge {
  const FlowLayoutEdge({
    required this.source,
    required this.target,
    this.weight = 1.0,
  });

  final FlowId source;
  final FlowId target;

  /// Relative importance. Hierarchical layouts use this to bias ordering.
  final double weight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowLayoutEdge &&
          other.source == source &&
          other.target == target &&
          other.weight == weight;

  @override
  int get hashCode => Object.hash(source, target, weight);
}

/// Spacing parameters for a layout.
@immutable
class FlowLayoutSpacing {
  const FlowLayoutSpacing({
    this.nodeSpacing = 40.0,
    this.layerSpacing = 80.0,
    this.padding = 0.0,
  });

  /// Gap between adjacent nodes within the same layer (perpendicular axis).
  final double nodeSpacing;

  /// Gap between layers (along the growth axis).
  final double layerSpacing;

  /// Optional padding around the entire result.
  final double padding;

  FlowLayoutSpacing copyWith({
    double? nodeSpacing,
    double? layerSpacing,
    double? padding,
  }) =>
      FlowLayoutSpacing(
        nodeSpacing: nodeSpacing ?? this.nodeSpacing,
        layerSpacing: layerSpacing ?? this.layerSpacing,
        padding: padding ?? this.padding,
      );
}

/// Input for a layout engine.
@immutable
class FlowLayoutInput {
  const FlowLayoutInput({
    required this.nodes,
    required this.edges,
    this.direction = FlowLayoutDirection.topToBottom,
    this.spacing = const FlowLayoutSpacing(),
    this.pinnedRects = const <FlowId, FlowRect>{},
  });

  final List<FlowLayoutNode> nodes;
  final List<FlowLayoutEdge> edges;
  final FlowLayoutDirection direction;
  final FlowLayoutSpacing spacing;

  /// Nodes that must keep these rects. Layout engines leave them alone.
  final Map<FlowId, FlowRect> pinnedRects;
}

/// Builds a [FlowLayoutInput] from a page.
///
/// Nodes with an empty rect get a default size of [defaultSize].
FlowLayoutInput layoutInputFromPage(
  FlowPage page, {
  FlowLayoutDirection direction = FlowLayoutDirection.topToBottom,
  FlowLayoutSpacing spacing = const FlowLayoutSpacing(),
  FlowSize defaultSize = const FlowSize(120, 60),
  Map<FlowId, FlowRect> pinnedRects = const <FlowId, FlowRect>{},
}) {
  final nodes = <FlowLayoutNode>[];
  for (final n in page.nodes.values) {
    final size = n.rect.isEmpty ? defaultSize : n.rect.size;
    nodes.add(FlowLayoutNode(
      id: n.id,
      size: size,
      currentRect: n.rect.isEmpty ? null : n.rect,
    ));
  }
  final edges = <FlowLayoutEdge>[
    for (final e in page.edges.values)
      FlowLayoutEdge(source: e.sourceNodeId, target: e.targetNodeId),
  ];
  return FlowLayoutInput(
    nodes: nodes,
    edges: edges,
    direction: direction,
    spacing: spacing,
    pinnedRects: pinnedRects,
  );
}

/// Convenience: build the input directly from a list of `FlowNode` and
/// `FlowEdge`.
FlowLayoutInput layoutInputFromNodes(
  Iterable<FlowNode> nodes,
  Iterable<FlowEdge> edges, {
  FlowLayoutDirection direction = FlowLayoutDirection.topToBottom,
  FlowLayoutSpacing spacing = const FlowLayoutSpacing(),
  FlowSize defaultSize = const FlowSize(120, 60),
  Map<FlowId, FlowRect> pinnedRects = const <FlowId, FlowRect>{},
}) {
  final list = <FlowLayoutNode>[];
  for (final n in nodes) {
    final size = n.rect.isEmpty ? defaultSize : n.rect.size;
    list.add(FlowLayoutNode(
      id: n.id,
      size: size,
      currentRect: n.rect.isEmpty ? null : n.rect,
    ));
  }
  final edgeList = <FlowLayoutEdge>[
    for (final e in edges)
      FlowLayoutEdge(source: e.sourceNodeId, target: e.targetNodeId),
  ];
  return FlowLayoutInput(
    nodes: list,
    edges: edgeList,
    direction: direction,
    spacing: spacing,
    pinnedRects: pinnedRects,
  );
}
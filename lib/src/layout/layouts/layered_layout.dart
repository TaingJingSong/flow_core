import 'dart:math' as math;

import '../../geometry/flow_rect.dart';
import '../../model/flow_id.dart';
import '../flow_layout_direction.dart';
import '../flow_layout_engine.dart';
import '../flow_layout_input.dart';
import '../flow_layout_result.dart';

/// Sugiyama-style layered layout for DAG-like flowcharts.
///
/// Steps:
/// 1. Build adjacency and detect back edges via DFS.
/// 2. Assign layers via longest-path from sources.
/// 3. Order within layers to reduce crossings, using barycenter passes.
/// 4. Assign coordinates centered along the perpendicular axis.
///
/// Cycles are broken by ignoring back edges during layering; the original
/// edges are still honored for ordering.
class LayeredLayout extends FlowLayoutEngine {
  const LayeredLayout({
    this.crossingReductionPasses = 4,
  });

  /// Number of barycenter sweeps. More passes = fewer crossings, slower.
  final int crossingReductionPasses;

  @override
  String get id => 'layered';

  @override
  String get name => 'Layered';

  @override
  FlowLayoutResult layout(FlowLayoutInput input) {
    if (input.nodes.isEmpty) return FlowLayoutResult(<FlowId, FlowRect>{});

    final nodeById = <FlowId, FlowLayoutNode>{
      for (final n in input.nodes) n.id: n,
    };

    // Filter edges to those with both endpoints present.
    final edges = <FlowLayoutEdge>[
      for (final e in input.edges)
        if (nodeById.containsKey(e.source) && nodeById.containsKey(e.target))
          e,
    ];

    // Remove self-edges.
    edges.removeWhere((e) => e.source == e.target);

    // 1. Detect back edges (DFS).
    final backEdges = _detectBackEdges(input.nodes.map((n) => n.id).toList(), edges);
    final dagEdges = edges.where((e) => !backEdges.contains(_key(e.source, e.target))).toList();

    // 2. Assign layers via longest path.
    final layerOf = _assignLayers(input.nodes.map((n) => n.id).toList(), dagEdges);

    // 3. Group into layers.
    final layers = <int, List<FlowId>>{};
    for (final n in input.nodes) {
      final l = layerOf[n.id] ?? 0;
      layers.putIfAbsent(l, () => <FlowId>[]).add(n.id);
    }

    // 4. Order within each layer using barycenter.
    final order = <int, List<FlowId>>{
      for (final e in layers.entries)
        e.key: List<FlowId>.of(e.value),
    };
    _reduceCrossings(order, dagEdges, layerOf, crossingReductionPasses);

    // 5. Assign coordinates.
    return _assignCoordinates(input, order, layerOf, nodeById);
  }

  // ---------------------------------------------------------------------------

  FlowLayoutResult _assignCoordinates(
    FlowLayoutInput input,
    Map<int, List<FlowId>> order,
    Map<FlowId, int> layerOf,
    Map<FlowId, FlowLayoutNode> nodeById,
  ) {
    final direction = input.direction;
    final spacing = input.spacing;
    final sortedLayers = order.keys.toList()..sort();

    // Measure each layer's main-axis size (thickness of the layer).
    final layerThickness = <int, double>{};
    for (final l in sortedLayers) {
      var maxThickness = 0.0;
      for (final id in order[l]!) {
        final s = nodeById[id]!.size;
        final t = direction.isVertical ? s.height : s.width;
        if (t > maxThickness) maxThickness = t;
      }
      layerThickness[l] = maxThickness;
    }

    // Compute main-axis offset of each layer.
    final layerMain = <int, double>{};
    var cursor = spacing.padding;
    for (final l in sortedLayers) {
      layerMain[l] = cursor;
      cursor += layerThickness[l]! + spacing.layerSpacing;
    }

    // Measure perpendicular extent of each layer.
    final layerWidth = <int, double>{};
    for (final l in sortedLayers) {
      var total = 0.0;
      for (final id in order[l]!) {
        final s = nodeById[id]!.size;
        total += direction.isVertical ? s.width : s.height;
      }
      total += spacing.nodeSpacing * (order[l]!.length - 1);
      layerWidth[l] = total;
    }

    // Widest layer determines overall perpendicular size.
    final maxWidth = layerWidth.values.isEmpty
        ? 0.0
        : layerWidth.values.reduce(math.max);

    // Place each node.
    final rects = <FlowId, FlowRect>{};
    for (final l in sortedLayers) {
      final ids = order[l]!;
      final layerStart = (maxWidth - layerWidth[l]!) / 2;
      var perpCursor = spacing.padding + layerStart;

      final mainOffset = layerMain[l]!;

      for (final id in ids) {
        final node = nodeById[id]!;
        final size = node.size;

        final FlowRect rect;
        if (direction.isVertical) {
          // Layer grows in y.
          final y = direction == FlowLayoutDirection.topToBottom
              ? mainOffset
              : -(mainOffset + size.height);
          rect = FlowRect.fromLTWH(perpCursor, y, size.width, size.height);
        } else {
          // Layer grows in x.
          final x = direction == FlowLayoutDirection.leftToRight
              ? mainOffset
              : -(mainOffset + size.width);
          rect = FlowRect.fromLTWH(x, perpCursor, size.width, size.height);
        }
        rects[id] = _respectPinned(input, id, rect);

        perpCursor += (direction.isVertical ? size.width : size.height) +
            spacing.nodeSpacing;
      }
    }
    return FlowLayoutResult(rects);
  }

  FlowRect _respectPinned(FlowLayoutInput input, FlowId id, FlowRect computed) {
    final pinned = input.pinnedRects[id];
    return pinned ?? computed;
  }

  // ---------------------------------------------------------------------------

  Set<String> _detectBackEdges(List<FlowId> nodeIds, List<FlowLayoutEdge> edges) {
    final adj = <FlowId, List<FlowId>>{};
    for (final id in nodeIds) {
      adj[id] = <FlowId>[];
    }
    for (final e in edges) {
      adj[e.source]!.add(e.target);
    }

    final color = <FlowId, int>{for (final id in nodeIds) id: 0};
    final back = <String>{};

    void visit(FlowId u) {
      color[u] = 1;
      for (final v in adj[u]!) {
        final c = color[v]!;
        if (c == 1) {
          back.add(_key(u, v));
        } else if (c == 0) {
          visit(v);
        }
      }
      color[u] = 2;
    }

    for (final id in nodeIds) {
      if (color[id] == 0) visit(id);
    }
    return back;
  }

  Map<FlowId, int> _assignLayers(List<FlowId> nodeIds, List<FlowLayoutEdge> edges) {
    final incoming = <FlowId, List<FlowId>>{
      for (final id in nodeIds) id: <FlowId>[],
    };
    for (final e in edges) {
      incoming[e.target]!.add(e.source);
    }

    // Longest path: layer[u] = max(layer[pred] + 1) over preds, or 0 for roots.
    // Memoize via post-order DFS.
    final layer = <FlowId, int>{};
    final visiting = <FlowId>{};

    int compute(FlowId u) {
      final cached = layer[u];
      if (cached != null) return cached;
      if (!visiting.add(u)) return 0; // Safety net for residual cycles.
      var best = 0;
      for (final p in incoming[u]!) {
        final v = compute(p) + 1;
        if (v > best) best = v;
      }
      visiting.remove(u);
      layer[u] = best;
      return best;
    }

    for (final id in nodeIds) {
      compute(id);
    }
    return layer;
  }

  void _reduceCrossings(
    Map<int, List<FlowId>> order,
    List<FlowLayoutEdge> edges,
    Map<FlowId, int> layerOf,
    int passes,
  ) {
    if (order.length < 2) return;

    final preds = <FlowId, List<FlowId>>{};
    final succs = <FlowId, List<FlowId>>{};
    for (final e in edges) {
      succs.putIfAbsent(e.source, () => []).add(e.target);
      preds.putIfAbsent(e.target, () => []).add(e.source);
    }

    final layerIds = order.keys.toList()..sort();

    for (var pass = 0; pass < passes; pass++) {
      final downward = pass.isEven;

      final sequence = downward ? layerIds : layerIds.reversed.toList();

      for (final l in sequence) {
        final ids = order[l]!;
        final neighbors = downward ? preds : succs;
        final positionInLayer = <FlowId, int>{};
        // Position of each node in the *adjacent* layer.
        for (final adjLayerEntry in order.entries) {
          if (adjLayerEntry.key == l) continue;
          for (var i = 0; i < adjLayerEntry.value.length; i++) {
            positionInLayer[adjLayerEntry.value[i]] = i;
          }
        }

        final scored = <_Scored>[];
        for (var i = 0; i < ids.length; i++) {
          final id = ids[i];
          final ns = neighbors[id] ?? const <FlowId>[];
          if (ns.isEmpty) {
            scored.add(_Scored(id, i.toDouble(), i));
            continue;
          }
          var sum = 0.0;
          var count = 0;
          for (final n in ns) {
            final p = positionInLayer[n];
            if (p != null) {
              sum += p;
              count++;
            }
          }
          final barycenter = count == 0 ? i.toDouble() : sum / count;
          scored.add(_Scored(id, barycenter, i));
        }

        scored.sort((a, b) {
          final c = a.score.compareTo(b.score);
          if (c != 0) return c;
          return a.originalIndex.compareTo(b.originalIndex);
        });

        order[l] = [for (final s in scored) s.id];
      }
    }
  }

  static String _key(FlowId a, FlowId b) => '${a.value}->${b.value}';
}

class _Scored {
  _Scored(this.id, this.score, this.originalIndex);
  final FlowId id;
  final double score;
  final int originalIndex;
}
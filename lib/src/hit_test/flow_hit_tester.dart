import '../geometry/edge_geometry.dart';
import '../geometry/flow_point.dart';
import '../geometry/flow_rect.dart';
import '../geometry/port_geometry.dart';
import '../geometry/segment_geometry.dart';
import '../model/flow_edge.dart';
import '../model/flow_id.dart';
import '../model/flow_node.dart';
import '../model/flow_page.dart';
import '../spatial/flow_spatial_index.dart';
import 'flow_hit_result.dart';
import '../routing/route_edge.dart';
import '../routing/flow_edge_router.dart';
import '../routing/flow_router_registry.dart';

/// Performs hit testing against a [FlowPage].
///
/// If [index] is provided, range queries go through the spatial index;
/// otherwise a linear scan is used. Linear scan is faster for small pages.
class FlowHitTester {
  FlowHitTester({
    required this.page,
    this.tolerance = 4.0,
    this.portRadius = 8.0,
    FlowSpatialIndex? index,
    FlowEdgeRouter? router,
    FlowRouterRegistry? routerRegistry,
  })  : _index = index,
        _router = router,
        _routerRegistry = routerRegistry;

  final FlowPage page;

  /// Extra slack (in logical pixels) around edges when hit testing.
  final double tolerance;

  /// Radius (in logical pixels) around a port for hit testing.
  final double portRadius;

  final FlowSpatialIndex? _index;
  final FlowEdgeRouter? _router;
  final FlowRouterRegistry? _routerRegistry;

  /// Hit test a single point.
  ///
  /// Priority order:
  /// 1. Ports (closest first, within [portRadius]).
  /// 2. Nodes (topmost first).
  /// 3. Edges (closest first, within [tolerance]).
  ///
  /// Nodes and ports are always reported; edges are reported only if no
  /// node was hit, to reduce noise during drags.
  FlowHitResult hitTestPoint(FlowPoint point) {
    final queryRect = FlowRect.fromLTWH(
      point.x - portRadius,
      point.y - portRadius,
      portRadius * 2,
      portRadius * 2,
    );

    final candidateNodes = _candidateNodes(queryRect);

    // Sort candidate nodes topmost first.
    final orderedNodes = _sortTopmostFirst(candidateNodes);

    // Ports: closest first.
    final portHits = <_PortCandidate>[];
    for (final n in orderedNodes) {
      for (final p in n.ports) {
        if (!p.isConnectable) continue;
        final pos = portPosition(n, p);
        final d = pos.distanceTo(point);
        if (d <= portRadius) {
          portHits.add(_PortCandidate(n.id, p.name, pos, d));
        }
      }
    }
    portHits.sort((a, b) => a.distance.compareTo(b.distance));

    // Nodes: exact containment.
    final hitNodes = <FlowNode>[];
    for (final n in orderedNodes) {
      if (!n.visible) continue;
      if (n.rect.contains(point)) hitNodes.add(n);
    }

    // Edges: only if no node was hit. Sorted by distance ascending.
    final hitEdges = <FlowEdge>[];
    if (hitNodes.isEmpty) {
      final candidateEdges = _candidateEdges(queryRect);
      final scored = <_EdgeCandidate>[];
      for (final e in candidateEdges) {
        if (!e.visible) continue;
        final path = routeEdge(
          e,
          page,
          router: _router,
          registry: _routerRegistry,
        );
        final d = path.distanceTo(point);
        if (d <= tolerance) scored.add(_EdgeCandidate(e, d));
      }
      scored.sort((a, b) => a.distance.compareTo(b.distance));
      hitEdges.addAll(scored.map((s) => s.edge));
    }

    return FlowHitResult(
      nodes: hitNodes,
      edges: hitEdges,
      ports: [
        for (final p in portHits)
          FlowPortHit(nodeId: p.nodeId, portName: p.portName, position: p.position),
      ],
    );
  }

  /// Hit test a rectangle (marquee).
  ///
  /// Returns every visible node whose rect intersects [rect], ordered
  /// topmost first, and every visible edge whose polyline intersects
  /// [rect]. Ports are not reported for rect queries.
  FlowHitResult hitTestRect(FlowRect rect) {
    final candidateNodes = _candidateNodes(rect);
    final orderedNodes = _sortTopmostFirst(candidateNodes)
        .where((n) => n.visible && n.rect.intersects(rect))
        .toList();

    final candidateEdges = _candidateEdges(rect);
    final hitEdges = <FlowEdge>[];
    for (final e in candidateEdges) {
      if (!e.visible) continue;
      final path = routeEdge(
        e,
        page,
        router: _router,
        registry: _routerRegistry,
      );
      if (_pathIntersectsRect(path.points, rect)) hitEdges.add(e);
    }

    return FlowHitResult(nodes: orderedNodes, edges: hitEdges);
  }

  // ---------------------------------------------------------------------------

  Iterable<FlowNode> _candidateNodes(FlowRect range) {
    final index = _index;
    if (index != null) return index.queryNodes(range);
    final out = <FlowNode>[];
    for (final n in page.nodes.values) {
      if (n.rect.intersects(range)) out.add(n);
    }
    return out;
  }

  Iterable<FlowEdge> _candidateEdges(FlowRect range) {
    final index = _index;
    if (index != null) return index.queryEdges(range);
    final out = <FlowEdge>[];
    for (final e in page.edges.values) {
      final b = edgeBounds(e, page);
      if (b.isEmpty) continue;
      if (b.intersects(range)) out.add(e);
    }
    return out;
  }

  List<FlowNode> _sortTopmostFirst(Iterable<FlowNode> nodes) {
    final insertion = <FlowId, int>{};
    var i = 0;
    for (final id in page.nodes.keys) {
      insertion[id] = i++;
    }
    final list = nodes.toList()
      ..sort((a, b) {
        final z = b.zIndex.compareTo(a.zIndex);
        if (z != 0) return z;
        final ai = insertion[a.id] ?? 0;
        final bi = insertion[b.id] ?? 0;
        return bi.compareTo(ai);
      });
    return list;
  }
}

class _PortCandidate {
  _PortCandidate(this.nodeId, this.portName, this.position, this.distance);
  final FlowId nodeId;
  final String portName;
  final FlowPoint position;
  final double distance;
}

class _EdgeCandidate {
  _EdgeCandidate(this.edge, this.distance);
  final FlowEdge edge;
  final double distance;
}

bool _pathIntersectsRect(List<FlowPoint> pts, FlowRect rect) {
  if (pts.isEmpty) return false;
  if (pts.length == 1) return rect.contains(pts.first);
  for (var i = 0; i < pts.length - 1; i++) {
    if (segmentIntersectsRect(pts[i], pts[i + 1], rect)) return true;
  }
  return false;
}
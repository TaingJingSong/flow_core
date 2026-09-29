import '../geometry/edge_geometry.dart';
import '../geometry/flow_rect.dart';
import '../model/flow_edge.dart';
import '../model/flow_node.dart';
import '../model/flow_page.dart';
import '../spatial/flow_quadtree.dart';

/// A per-page spatial index for nodes and edges.
///
/// Build it once per page revision. Queries return candidates; exact hit
/// testing is the caller's job.
class FlowSpatialIndex {
  FlowSpatialIndex._(this._nodes, this._edges, this._page);

  /// Builds an index from [page].
  factory FlowSpatialIndex.build(FlowPage page) {
    final nodeTree = FlowQuadtree<FlowNode>.empty();
    for (final n in page.nodes.values) {
      nodeTree.insert(n, n.rect);
    }
    final edgeTree = FlowQuadtree<FlowEdge>.empty();
    for (final e in page.edges.values) {
      final b = edgeBounds(e, page);
      if (b.isEmpty) continue;
      edgeTree.insert(e, b);
    }
    return FlowSpatialIndex._(nodeTree, edgeTree, page);
  }

  final FlowQuadtree<FlowNode> _nodes;
  final FlowQuadtree<FlowEdge> _edges;
  final FlowPage _page;

  /// Number of nodes indexed.
  int get nodeCount => _nodes.length;

  /// Number of edges indexed.
  int get edgeCount => _edges.length;

  /// Candidate nodes whose rects intersect [range].
  Iterable<FlowNode> queryNodes(FlowRect range) => _nodes.query(range);

  /// Candidate edges whose polylines' bounding boxes intersect [range].
  Iterable<FlowEdge> queryEdges(FlowRect range) => _edges.query(range);

  /// The page this index was built from.
  FlowPage get page => _page;
}
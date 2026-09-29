import 'dart:math' as math;

import '../../geometry/flow_rect.dart';
import '../../model/flow_id.dart';
import '../flow_layout_direction.dart';
import '../flow_layout_engine.dart';
import '../flow_layout_input.dart';
import '../flow_layout_result.dart';

/// Tidy tree layout (Reingold–Tilford style).
///
/// Roots are nodes with no incoming edges. Multiple roots are laid out
/// as a forest, side by side. When the graph has no roots (fully cyclic),
/// the first node is used as root.
///
/// Nodes reachable from any root are placed. Unreachable nodes are laid
/// out as isolated roots next to the forest.
class TreeLayout extends FlowLayoutEngine {
  const TreeLayout({this.siblingSpacing = 30.0});

  /// Extra gap between siblings at the same depth.
  final double siblingSpacing;

  @override
  String get id => 'tree';

  @override
  String get name => 'Tree';

  @override
  FlowLayoutResult layout(FlowLayoutInput input) {
    if (input.nodes.isEmpty) return FlowLayoutResult(<FlowId, FlowRect>{});

    final nodeById = <FlowId, FlowLayoutNode>{
      for (final n in input.nodes) n.id: n,
    };

    // Build tree by DFS, avoiding cycles.
    final children = <FlowId, List<FlowId>>{
      for (final n in input.nodes) n.id: <FlowId>[],
    };
    final incoming = <FlowId, int>{for (final n in input.nodes) n.id: 0};
    for (final e in input.edges) {
      if (!nodeById.containsKey(e.source)) continue;
      if (!nodeById.containsKey(e.target)) continue;
      if (e.source == e.target) continue;
      incoming[e.target] = (incoming[e.target] ?? 0) + 1;
    }
    // Assign parents via BFS from roots.
    final visited = <FlowId>{};
    final roots = <FlowId>[
      for (final n in input.nodes)
        if ((incoming[n.id] ?? 0) == 0) n.id,
    ];
    if (roots.isEmpty) roots.add(input.nodes.first.id);

    // Add any unreachable nodes as additional roots.
    for (final n in input.nodes) {
      if (incoming[n.id] == 0 && !roots.contains(n.id)) {
        roots.add(n.id);
      }
    }

    for (final root in roots) {
      if (visited.contains(root)) continue;
      final queue = <FlowId>[root];
      visited.add(root);
      while (queue.isNotEmpty) {
        final u = queue.removeAt(0);
        for (final e in input.edges) {
          if (e.source != u) continue;
          if (!nodeById.containsKey(e.target)) continue;
          if (visited.contains(e.target)) continue;
          if (e.target == u) continue;
          children[u]!.add(e.target);
          visited.add(e.target);
          queue.add(e.target);
        }
      }
    }

    // Any nodes still not visited become their own roots.
    for (final n in input.nodes) {
      if (!visited.contains(n.id)) {
        roots.add(n.id);
        visited.add(n.id);
      }
    }

    // Build a forest: one tree per root, packed left-to-right
    // (perpendicular to direction).
    final trees = <_Tree>[
      for (final r in roots) _Tree(root: r, children: children, nodeById: nodeById),
    ];

    final direction = input.direction;
    final spacing = input.spacing;

    // Depth per node, for main-axis placement.
    final depthOf = <FlowId, int>{};
    void assignDepths(FlowId id, int depth) {
      depthOf[id] = depth;
      for (final c in children[id]!) {
        assignDepths(c, depth + 1);
      }
    }
    for (final r in roots) {
      assignDepths(r, 0);
    }

    // Max height per depth (main axis).
    final maxThicknessByDepth = <int, double>{};
    for (final entry in depthOf.entries) {
      final s = nodeById[entry.key]!.size;
      final t = direction.isVertical ? s.height : s.width;
      final cur = maxThicknessByDepth[entry.value] ?? 0;
      if (t > cur) maxThicknessByDepth[entry.value] = t;
    }

    // Main-axis offsets per depth.
    final depthMain = <int, double>{};
    var cursor = spacing.padding;
    final maxDepth = depthOf.values.isEmpty
        ? 0
        : depthOf.values.reduce(math.max);
    for (var d = 0; d <= maxDepth; d++) {
      depthMain[d] = cursor;
      cursor += (maxThicknessByDepth[d] ?? 0) + spacing.layerSpacing;
    }

    // Lay out each tree, packing along the perpendicular axis.
    final rects = <FlowId, FlowRect>{};
    var packCursor = spacing.padding;
    for (final tree in trees) {
      final treeWidth = tree.computeWidth(siblingSpacing, direction);
      tree.place(
        packCursor,
        depthMain,
        direction,
        rects,
        siblingSpacing,
      );
      packCursor += treeWidth + spacing.nodeSpacing;
    }

    // Apply pinned rects (they win).
    for (final entry in input.pinnedRects.entries) {
      rects[entry.key] = entry.value;
    }

    return FlowLayoutResult(rects);
  }
}

class _Tree {
  _Tree({
    required this.root,
    required this.children,
    required this.nodeById,
  });

  final FlowId root;
  final Map<FlowId, List<FlowId>> children;
  final Map<FlowId, FlowLayoutNode> nodeById;

  double _width = 0;
  final Map<FlowId, double> _subtreeWidths = <FlowId, double>{};

  /// Computes the total width of the tree along the perpendicular axis.
  double computeWidth(double siblingSpacing, FlowLayoutDirection direction) {
    _subtreeWidths.clear();
    _width = _computeWidth(root, siblingSpacing, direction);
    return _width;
  }

  double _computeWidth(
    FlowId id,
    double siblingSpacing,
    FlowLayoutDirection direction,
  ) {
    final node = nodeById[id]!;
    final self = direction.isVertical ? node.size.width : node.size.height;
    final kids = children[id]!;
    if (kids.isEmpty) {
      _subtreeWidths[id] = self;
      return self;
    }

    var total = 0.0;
    for (var i = 0; i < kids.length; i++) {
      if (i > 0) total += siblingSpacing;
      total += _computeWidth(kids[i], siblingSpacing, direction);
    }
    final w = math.max(self, total);
    _subtreeWidths[id] = w;
    return w;
  }

  void place(
    double leftEdge,
    Map<int, double> depthMain,
    FlowLayoutDirection direction,
    Map<FlowId, FlowRect> rects,
    double siblingSpacing,
  ) {
    _placeRecursive(
      root,
      leftEdge,
      depthMain,
      direction,
      rects,
      siblingSpacing,
      0,
    );
  }

  /// Returns the perpendicular center of this subtree.
  double _placeRecursive(
    FlowId id,
    double leftEdge,
    Map<int, double> depthMain,
    FlowLayoutDirection direction,
    Map<FlowId, FlowRect> rects,
    double siblingSpacing,
    int depth,
  ) {
    final node = nodeById[id]!;
    final self = direction.isVertical ? node.size.width : node.size.height;
    final mainSize = direction.isVertical ? node.size.height : node.size.width;
    final kids = children[id]!;

    final double perpCenter;
    if (kids.isEmpty) {
      perpCenter = leftEdge + self / 2;
    } else {
      var totalKidsWidth = 0.0;
      for (var i = 0; i < kids.length; i++) {
        if (i > 0) totalKidsWidth += siblingSpacing;
        totalKidsWidth += _subtreeWidths[kids[i]]!;
      }
      final kidsOffset =
          self > totalKidsWidth ? (self - totalKidsWidth) / 2 : 0.0;
      var cursor = leftEdge + kidsOffset;
      final childCenters = <double>[];
      for (var i = 0; i < kids.length; i++) {
        if (i > 0) cursor += siblingSpacing;
        final childWidth = _subtreeWidths[kids[i]]!;
        final c = _placeRecursive(
          kids[i],
          cursor,
          depthMain,
          direction,
          rects,
          siblingSpacing,
          depth + 1,
        );
        childCenters.add(c);
        cursor += childWidth;
      }
      perpCenter = (childCenters.first + childCenters.last) / 2;
    }

    // Position along the perpendicular axis.
    final perp = perpCenter - self / 2;

    // Position along the main axis.
    final main = depthMain[depth]!;

    final FlowRect rect;
    if (direction.isVertical) {
      final y = direction == FlowLayoutDirection.topToBottom
          ? main
          : -(main + mainSize);
      rect = FlowRect.fromLTWH(perp, y, node.size.width, node.size.height);
    } else {
      final x = direction == FlowLayoutDirection.leftToRight
          ? main
          : -(main + mainSize);
      rect = FlowRect.fromLTWH(x, perp, node.size.width, node.size.height);
    }
    rects[id] = rect;
    return perpCenter;
  }
}
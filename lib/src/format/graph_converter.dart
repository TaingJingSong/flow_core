import '../geometry/flow_rect.dart';
import '../geometry/flow_size.dart';
import '../layout/flow_layout_input.dart';
import '../layout/flow_layout_registry.dart';
import '../layout/flow_layout_result.dart';
import '../layout/layouts/layered_layout.dart';
import '../model/flow_color.dart';
import '../model/flow_document.dart';
import '../model/flow_edge.dart';
import '../model/flow_group.dart';
import '../model/flow_id.dart';
import '../model/flow_label.dart';
import '../model/flow_layer.dart';
import '../model/flow_node.dart';
import '../model/flow_page.dart';
import '../model/flow_style.dart';
import 'flow_graph.dart';

/// Converts between [FlowGraph] and [FlowDocument].
///
/// When the graph lacks positions, a layout engine is chosen by
/// [FlowGraph.suggestedLayout] and run. When positions exist (draw.io),
/// they are used as-is.
class FlowGraphConverter {
  const FlowGraphConverter({
    this.defaultNodeSize = const FlowSize(160, 50),
    this.layoutRegistry,
  });

  final FlowSize defaultNodeSize;
  final FlowLayoutRegistry? layoutRegistry;

  // ---------------------------------------------------------------------------
  // Graph → Document
  // ---------------------------------------------------------------------------

  /// Builds a [FlowDocument] from [graph].
  FlowDocument toDocument(
    FlowGraph graph, {
    bool runLayout = true,
    String documentId = 'doc',
    String documentName = 'Untitled',
    String pageId = 'page_1',
    String layerId = 'default',
  }) {
    final rects = _computeRects(graph, runLayout);

    final nodes = <FlowId, FlowNode>{};
    for (final gn in graph.nodes.values) {
      final rect = rects[gn.id] ??
          FlowRect.fromLTWH(0, 0, defaultNodeSize.width, defaultNodeSize.height);
      nodes[FlowId(gn.id)] = FlowNode(
        id: FlowId(gn.id),
        type: gn.shape,
        rect: rect,
        label: gn.label.isEmpty ? null : FlowLabel(text: gn.label),
        layerId: FlowId(layerId),
        parentGroupId: gn.groupId == null ? null : FlowId(gn.groupId!),
        tags: gn.tags,
        meta: {...gn.meta},
        data: {...gn.data},
      );
    }

    final edges = <FlowId, FlowEdge>{};
    for (final ge in graph.edges.values) {
      edges[FlowId(ge.id)] = FlowEdge(
        id: FlowId(ge.id),
        sourceNodeId: FlowId(ge.source),
        targetNodeId: FlowId(ge.target),
        sourcePortName: ge.sourcePort,
        targetPortName: ge.targetPort,
        kind: ge.kind,
        sourceArrow: ge.sourceArrow,
        targetArrow: ge.targetArrow,
        label: ge.label.isEmpty ? null : FlowLabel(text: ge.label),
        style: _edgeStyle(ge),
        meta: {...ge.meta},
        data: {...ge.data},
      );
    }

    final groups = <FlowId, FlowGroup>{};
    for (final gg in graph.groups.values) {
      final childRects = <FlowRect>[];
      for (final id in gg.nodeIds) {
        final r = rects[id];
        if (r != null) childRects.add(r);
      }
      if (childRects.isEmpty) continue;
      var bounds = childRects.first;
      for (var i = 1; i < childRects.length; i++) {
        bounds = bounds.union(childRects[i]);
      }
      groups[FlowId(gg.id)] = FlowGroup(
        id: FlowId(gg.id),
        rect: bounds.inflate(20),
        label: gg.label.isEmpty ? null : FlowLabel(text: gg.label),
        childNodeIds: [for (final id in gg.nodeIds) FlowId(id)],
        childGroupIds: [for (final id in gg.childGroupIds) FlowId(id)],
        parentGroupId: gg.parentId == null ? null : FlowId(gg.parentId!),
        meta: {...gg.meta},
      );
    }

    final layer = FlowLayer(id: FlowId(layerId), name: 'Default');

    final page = FlowPage(
      id: FlowId(pageId),
      name: 'Page',
      layers: {layer.id: layer},
      nodes: nodes,
      edges: edges,
      groups: groups,
    );

    return FlowDocument(
      id: FlowId(documentId),
      name: documentName,
      pages: [page],
    );
  }

  Map<String, FlowRect> _computeRects(FlowGraph graph, bool runLayout) {
    final rects = <String, FlowRect>{};
    var allHaveRects = true;
    for (final n in graph.nodes.values) {
      final r = n.rect;
      if (r != null) {
        rects[n.id] = r;
      } else {
        allHaveRects = false;
      }
    }

    if (allHaveRects || !runLayout) {
      for (final n in graph.nodes.values) {
        rects.putIfAbsent(
          n.id,
          () => FlowRect.fromLTWH(
            0,
            0,
            defaultNodeSize.width,
            defaultNodeSize.height,
          ),
        );
      }
      return rects;
    }

    final registry = layoutRegistry ?? FlowLayoutRegistry();
    final engine =
        registry.byId(graph.suggestedLayout) ?? const LayeredLayout();

    final input = FlowLayoutInput(
      nodes: [
        for (final n in graph.nodes.values)
          FlowLayoutNode(
            id: FlowId(n.id),
            size: n.rect?.size ?? defaultNodeSize,
            currentRect: n.rect,
          ),
      ],
      edges: [
        for (final e in graph.edges.values)
          FlowLayoutEdge(source: FlowId(e.source), target: FlowId(e.target)),
      ],
      direction: graph.suggestedDirection,
    );

    final FlowLayoutResult result = engine.layout(input);
    for (final entry in result.rects.entries) {
      rects[entry.key.value] = entry.value;
    }
    return rects;
  }

  FlowStyle _edgeStyle(FlowGraphEdge ge) {
    var s = FlowStyle.defaults.copyWith(
      strokeColor: const FlowColor(0xFF000000),
      strokeWidth: ge.thick ? 2.5 : 1.0,
    );
    if (ge.dashed) {
      s = s.copyWith(strokeDashPattern: const [6, 4]);
    }
    return s;
  }
}
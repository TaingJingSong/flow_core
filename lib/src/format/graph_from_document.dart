import '../model/flow_document.dart';
import 'flow_graph.dart';

/// Converts a [FlowDocument] to a [FlowGraph].
///
/// Positions are dropped; the graph is purely semantic.
FlowGraph documentToFlowGraph(FlowDocument doc) {
  final page = doc.firstPage;
  if (page == null) return FlowGraph();

  final nodes = <String, FlowGraphNode>{};
  for (final n in page.nodes.values) {
    nodes[n.id.value] = FlowGraphNode(
      id: n.id.value,
      label: n.label?.text ?? '',
      shape: n.type,
      groupId: n.parentGroupId?.value,
      tags: n.tags,
      meta: n.meta,
      data: n.data,
    );
  }

  final edges = <String, FlowGraphEdge>{};
  for (final e in page.edges.values) {
    edges[e.id.value] = FlowGraphEdge(
      id: e.id.value,
      source: e.sourceNodeId.value,
      target: e.targetNodeId.value,
      sourcePort: e.sourcePortName,
      targetPort: e.targetPortName,
      label: e.label?.text ?? '',
      kind: e.kind,
      sourceArrow: e.sourceArrow,
      targetArrow: e.targetArrow,
      dashed: e.style.strokeDashPattern != null,
      thick: (e.style.strokeWidth ?? 1.0) > 2.0,
      meta: e.meta,
      data: e.data,
    );
  }

  final groups = <String, FlowGraphGroup>{};
  for (final g in page.groups.values) {
    groups[g.id.value] = FlowGraphGroup(
      id: g.id.value,
      label: g.label?.text ?? '',
      parentId: g.parentGroupId?.value,
      nodeIds: [for (final id in g.childNodeIds) id.value],
      childGroupIds: [for (final id in g.childGroupIds) id.value],
      meta: g.meta,
    );
  }

  return FlowGraph(nodes: nodes, edges: edges, groups: groups);
}
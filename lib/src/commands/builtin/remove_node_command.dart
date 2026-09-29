import '../../model/flow_edge.dart';
import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import '../../model/flow_page.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Removes a node and every edge incident to it.
///
/// Captures the full page before removal so undo can restore the exact
/// insertion order of nodes and edges. This is safe because the undo
/// stack is LIFO: when this command is undone, the page is guaranteed
/// to be in the state immediately after the removal.
class RemoveNodeCommand extends FlowCommand {
  RemoveNodeCommand({required this.pageId, required this.nodeId});

  final FlowId pageId;
  final FlowId nodeId;

  FlowPage? _snapshot;

  @override
  String get label => 'Remove node';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (!page.nodes.containsKey(nodeId)) return;

    _snapshot = page;

    final nodes = <FlowId, FlowNode>{
      for (final e in page.nodes.entries)
        if (e.key != nodeId) e.key: e.value,
    };
    final edges = <FlowId, FlowEdge>{
      for (final e in page.edges.entries)
        if (!_touches(e.value)) e.key: e.value,
    };

    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes, edges: edges),
    );
  }

  @override
  void undo(FlowDocumentState state) {
    if (_snapshot == null) return;
    state.document = replacePage(state.document, _snapshot!);
  }

  bool _touches(FlowEdge edge) =>
      edge.sourceNodeId == nodeId || edge.targetNodeId == nodeId;
}
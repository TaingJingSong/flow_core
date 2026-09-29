import '../../model/flow_edge.dart';
import '../../model/flow_id.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Removes a single edge.
class RemoveEdgeCommand extends FlowCommand {
  RemoveEdgeCommand({required this.pageId, required this.edgeId});

  final FlowId pageId;
  final FlowId edgeId;

  FlowEdge? _removed;
  int? _index;

  @override
  String get label => 'Remove edge';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    final edge = page.edges[edgeId];
    if (edge == null) return;
    _removed = edge;
    _index = indexOfKey(page.edges, edgeId);
    final edges = Map<FlowId, FlowEdge>.of(page.edges)..remove(edgeId);
    state.document = replacePage(
      state.document,
      page.copyWith(edges: edges),
    );
  }

  @override
  void undo(FlowDocumentState state) {
    final edge = _removed;
    final idx = _index;
    if (edge == null || idx == null) return;
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (page.edges.containsKey(edgeId)) return;
    final edges = insertAt(page.edges, idx, edgeId, edge);
    state.document = replacePage(
      state.document,
      page.copyWith(edges: edges),
    );
  }
}
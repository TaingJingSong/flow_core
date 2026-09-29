import '../../model/flow_edge.dart';
import '../../model/flow_id.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Adds [edge] to the page identified by [pageId].
class AddEdgeCommand extends FlowCommand {
  AddEdgeCommand({required this.pageId, required this.edge});

  final FlowId pageId;
  final FlowEdge edge;

  @override
  String get label => 'Add edge';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (page.edges.containsKey(edge.id)) return;
    final edges = Map<FlowId, FlowEdge>.of(page.edges)..[edge.id] = edge;
    state.document = replacePage(
      state.document,
      page.copyWith(edges: edges),
    );
  }

  @override
  void undo(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (!page.edges.containsKey(edge.id)) return;
    final edges = Map<FlowId, FlowEdge>.of(page.edges)..remove(edge.id);
    state.document = replacePage(
      state.document,
      page.copyWith(edges: edges),
    );
  }
}
import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Adds [node] to the page identified by [pageId].
class AddNodeCommand extends FlowCommand {
  AddNodeCommand({required this.pageId, required this.node});

  final FlowId pageId;
  final FlowNode node;

  @override
  String get label => 'Add node';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (page.nodes.containsKey(node.id)) return;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes)..[node.id] = node;
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }

  @override
  void undo(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    if (!page.nodes.containsKey(node.id)) return;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes)..remove(node.id);
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }
}
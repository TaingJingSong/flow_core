import '../../geometry/flow_rect.dart';
import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Sets the absolute rect of a single node. Non-mergeable.
///
/// Used for resize and for setting the final position after a drag session.
class SetNodeRectCommand extends FlowCommand {
  SetNodeRectCommand({
    required this.pageId,
    required this.nodeId,
    required this.rect,
  });

  final FlowId pageId;
  final FlowId nodeId;
  final FlowRect rect;

  FlowRect? _previous;

  @override
  String get label => 'Resize node';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    final node = page.nodes[nodeId];
    if (node == null) return;
    _previous = node.rect;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes)
      ..[nodeId] = node.copyWith(rect: rect);
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }

  @override
  void undo(FlowDocumentState state) {
    final prev = _previous;
    if (prev == null) return;
    final page = state.document.pageById(pageId);
    if (page == null) return;
    final node = page.nodes[nodeId];
    if (node == null) return;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes)
      ..[nodeId] = node.copyWith(rect: prev);
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }
}
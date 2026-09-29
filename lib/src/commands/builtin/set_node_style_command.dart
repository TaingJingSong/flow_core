import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import '../../model/flow_style.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Replaces the style of a single node. Non-mergeable.
class SetNodeStyleCommand extends FlowCommand {
  SetNodeStyleCommand({
    required this.pageId,
    required this.nodeId,
    required this.style,
  });

  final FlowId pageId;
  final FlowId nodeId;
  final FlowStyle style;

  FlowStyle? _previous;

  @override
  String get label => 'Change style';

  @override
  void execute(FlowDocumentState state) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    final node = page.nodes[nodeId];
    if (node == null) return;
    _previous = node.style;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes)
      ..[nodeId] = node.copyWith(style: style);
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
      ..[nodeId] = node.copyWith(style: prev);
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }
}
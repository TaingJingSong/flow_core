import '../../geometry/flow_point.dart';
import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import '../flow_command.dart';
import '../flow_document_state.dart';
import '../utils/page_edits.dart';

/// Translates [nodeIds] by [delta]. Mergeable: consecutive moves on the
/// same set of nodes combine into one history entry.
class MoveNodesCommand extends FlowCommand {
  MoveNodesCommand({
    required this.pageId,
    required this.nodeIds,
    required this.delta,
  });

  final FlowId pageId;
  final List<FlowId> nodeIds;
  final FlowPoint delta;

  @override
  String get label => nodeIds.length == 1 ? 'Move node' : 'Move nodes';

  @override
  bool get isMergeable => true;

  @override
  FlowCommand? merge(FlowCommand next) {
    if (next is! MoveNodesCommand) return null;
    if (next.pageId != pageId) return null;
    if (!_sameSet(nodeIds, next.nodeIds)) return null;
    return MoveNodesCommand(
      pageId: pageId,
      nodeIds: nodeIds,
      delta: FlowPoint(delta.x + next.delta.x, delta.y + next.delta.y),
    );
  }

  @override
  void execute(FlowDocumentState state) => _apply(state, delta);

  @override
  void undo(FlowDocumentState state) => _apply(state, -delta);

  void _apply(FlowDocumentState state, FlowPoint d) {
    final page = state.document.pageById(pageId);
    if (page == null) return;
    final nodes = Map<FlowId, FlowNode>.of(page.nodes);
    var changed = false;
    for (final id in nodeIds) {
      final node = nodes[id];
      if (node == null) continue;
      nodes[id] = node.copyWith(rect: node.rect.translate(d.x, d.y));
      changed = true;
    }
    if (!changed) return;
    state.document = replacePage(
      state.document,
      page.copyWith(nodes: nodes),
    );
  }

  static bool _sameSet(List<FlowId> a, List<FlowId> b) {
    if (a.length != b.length) return false;
    final set = a.toSet();
    for (final id in b) {
      if (!set.contains(id)) return false;
    }
    return true;
  }
}
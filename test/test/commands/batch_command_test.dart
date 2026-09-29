import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  test('BatchCommand executes in order and undoes in reverse', () {
    final state = FlowDocumentState(FlowDocument.empty(id: const FlowId('doc')));
    const pageId = FlowId('page_1');

    final cmd = BatchCommand(label: 'Setup', commands: [
      AddNodeCommand(
        pageId: pageId,
        node: FlowNode(
          id: FlowId('n1'),
          type: 'rectangle',
          rect: FlowRect.fromLTWH(0, 0, 100, 40),
        ),
      ),
      AddNodeCommand(
        pageId: pageId,
        node: FlowNode(
          id: FlowId('n2'),
          type: 'rectangle',
          rect: FlowRect.fromLTWH(200, 0, 100, 40),
        ),
      ),
    ]);

    cmd.execute(state);
    expect(state.document.pages.first.nodes, hasLength(2));

    cmd.undo(state);
    expect(state.document.pages.first.nodes, isEmpty);
  });
}
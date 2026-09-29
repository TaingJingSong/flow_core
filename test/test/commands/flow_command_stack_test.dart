import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowDocument emptyDoc() => FlowDocument.empty(id: const FlowId('doc'));

FlowId firstPageId(FlowDocument doc) => doc.pages.first.id;

const pageId = FlowId('page_1');

FlowNode node(String id, {double x = 0, double y = 0}) => FlowNode(
      id: FlowId(id),
      type: 'rectangle',
      rect: FlowRect.fromLTWH(x, y, 100, 40),
    );

void main() {
  group('FlowCommandStack', () {
    late FlowDocumentState state;
    late FlowCommandStack stack;

    setUp(() {
      state = FlowDocumentState(emptyDoc());
      stack = FlowCommandStack(state: state);
    });

    tearDown(() => stack.dispose());

    test('starts empty', () {
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });

    test('execute and undo add node', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      expect(state.document.pages.first.nodes, hasLength(1));
      stack.undo();
      expect(state.document.pages.first.nodes, isEmpty);
      stack.redo();
      expect(state.document.pages.first.nodes, hasLength(1));
    });

    test('new command clears redo stack', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      stack.undo();
      expect(stack.canRedo, isTrue);
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n2')));
      expect(stack.canRedo, isFalse);
    });

    test('undo restores exact previous state', () {
      final initial = state.document;
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      stack.undo();
      expect(state.document, initial);
    });

    test('remove node also removes incident edges', () {
      final a = node('a');
      final b = node('b', x: 200);
      stack.execute(AddNodeCommand(pageId: pageId, node: a));
      stack.execute(AddNodeCommand(pageId: pageId, node: b));
      stack.execute(AddEdgeCommand(
        pageId: pageId,
        edge: FlowEdge(
          id: const FlowId('e1'),
          sourceNodeId: const FlowId('a'),
          targetNodeId: const FlowId('b'),
        ),
      ));

      stack.execute(
        RemoveNodeCommand(pageId: pageId, nodeId: const FlowId('a')),
      );
      final page = state.document.pages.first;
      expect(page.nodes.containsKey(const FlowId('a')), isFalse);
      expect(page.edges, isEmpty);

      stack.undo();
      final restored = state.document.pages.first;
      expect(restored.nodes.containsKey(const FlowId('a')), isTrue);
      expect(restored.edges, hasLength(1));
    });

    test('move nodes merges within window', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      final clock = _FakeClock(DateTime(2025, 1, 1));
      final mergeStack = FlowCommandStack(
        state: state,
        now: clock.now,
      );
      // Note: separate stack but same state; use it instead.
      mergeStack.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('n1')],
        delta: const FlowPoint(1, 0),
      ));
      clock.advance(const Duration(milliseconds: 100));
      mergeStack.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('n1')],
        delta: const FlowPoint(2, 0),
      ));
      expect(mergeStack.undoLength, 1);

      mergeStack.undo();
      final n = state.document.pages.first.nodes[const FlowId('n1')]!;
      expect(n.rect.left, 0);
      mergeStack.dispose();
    });

    test('move nodes outside window does not merge', () {
      final clock = _FakeClock(DateTime(2025, 1, 1));
      final s = FlowCommandStack(state: state, now: clock.now);
      s.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      s.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('n1')],
        delta: const FlowPoint(1, 0),
      ));
      clock.advance(const Duration(seconds: 2));
      s.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('n1')],
        delta: const FlowPoint(2, 0),
      ));
      expect(s.undoLength, 3);
      s.dispose();
    });

    test('different node sets do not merge', () {
      final clock = _FakeClock(DateTime(2025, 1, 1));
      final s = FlowCommandStack(state: state, now: clock.now);
      s.execute(AddNodeCommand(pageId: pageId, node: node('a')));
      s.execute(AddNodeCommand(pageId: pageId, node: node('b', x: 200)));
      s.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('a')],
        delta: const FlowPoint(1, 0),
      ));
      s.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('b')],
        delta: const FlowPoint(1, 0),
      ));
      expect(s.undoLength, 4);
      s.dispose();
    });

    test('batch executes atomically and undoes in reverse', () {
      final initial = state.document;
      stack.executeAll([
        AddNodeCommand(pageId: pageId, node: node('n1')),
        AddNodeCommand(pageId: pageId, node: node('n2', x: 200)),
        AddEdgeCommand(
          pageId: pageId,
          edge: FlowEdge(
            id: const FlowId('e1'),
            sourceNodeId: const FlowId('n1'),
            targetNodeId: const FlowId('n2'),
          ),
        ),
      ]);
      final page = state.document.pages.first;
      expect(page.nodes, hasLength(2));
      expect(page.edges, hasLength(1));

      stack.undo();
      expect(state.document, initial);
    });

    test('history limit drops oldest entries', () {
      final clock = _FakeClock(DateTime(2025, 1, 1));
      final s = FlowCommandStack(
        state: state,
        historyLimit: 2,
        now: clock.now,
      );
      for (var i = 0; i < 5; i++) {
        s.execute(AddNodeCommand(pageId: pageId, node: node('n$i', x: i * 50)));
        clock.advance(const Duration(seconds: 1));
      }
      expect(s.undoLength, 2);
      s.dispose();
    });

    test('events fire on execute, undo, redo', () async {
      final events = <FlowHistoryEvent>[];
      final sub = stack.events.listen(events.add);
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      stack.undo();
      stack.redo();
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(3));
      expect(events.last.canUndo, isTrue);
      expect(events.last.canRedo, isFalse);
      await sub.cancel();
    });

    test('round-trip: many operations and full undo restores original', () {
      final original = state.document;
      stack.execute(AddNodeCommand(pageId: pageId, node: node('a')));
      stack.execute(AddNodeCommand(pageId: pageId, node: node('b', x: 200)));
      stack.execute(MoveNodesCommand(
        pageId: pageId,
        nodeIds: const [FlowId('a')],
        delta: const FlowPoint(10, 20),
      ));
      stack.execute(AddEdgeCommand(
        pageId: pageId,
        edge: FlowEdge(
          id: const FlowId('e1'),
          sourceNodeId: const FlowId('a'),
          targetNodeId: const FlowId('b'),
        ),
      ));
      stack.execute(
        RemoveNodeCommand(pageId: pageId, nodeId: const FlowId('a')),
      );

      while (stack.canUndo) {
        stack.undo();
      }
      expect(state.document, original);

      while (stack.canRedo) {
        stack.redo();
      }
      expect(state.document.pages.first.nodes, hasLength(1));
      expect(state.document.pages.first.edges, isEmpty);
    });

    test('set node rect undo restores previous rect', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      stack.execute(SetNodeRectCommand(
        pageId: pageId,
        nodeId: const FlowId('n1'),
        rect: FlowRect.fromLTWH(50, 50, 200, 80),
      ));
      var n = state.document.pages.first.nodes[const FlowId('n1')]!;
      expect(n.rect.left, 50);
      stack.undo();
      n = state.document.pages.first.nodes[const FlowId('n1')]!;
      expect(n.rect.left, 0);
      expect(n.rect.width, 100);
    });

    test('set node style undo restores previous style', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('n1')));
      const newStyle = FlowStyle(fillColor: FlowColor.redColor, cornerRadius: 8);
      stack.execute(SetNodeStyleCommand(
        pageId: pageId,
        nodeId: const FlowId('n1'),
        style: newStyle,
      ));
      var n = state.document.pages.first.nodes[const FlowId('n1')]!;
      expect(n.style, newStyle);
      stack.undo();
      n = state.document.pages.first.nodes[const FlowId('n1')]!;
      expect(n.style, FlowStyle.defaults);
    });

    test('remove edge undo restores insertion order', () {
      stack.execute(AddNodeCommand(pageId: pageId, node: node('a')));
      stack.execute(AddNodeCommand(pageId: pageId, node: node('b', x: 200)));
      stack.execute(AddEdgeCommand(
        pageId: pageId,
        edge: FlowEdge(
          id: const FlowId('e1'),
          sourceNodeId: const FlowId('a'),
          targetNodeId: const FlowId('b'),
        ),
      ));
      stack.execute(AddEdgeCommand(
        pageId: pageId,
        edge: FlowEdge(
          id: const FlowId('e2'),
          sourceNodeId: const FlowId('b'),
          targetNodeId: const FlowId('a'),
        ),
      ));

      stack.execute(
        RemoveEdgeCommand(pageId: pageId, edgeId: const FlowId('e1')),
      );
      expect(
        state.document.pages.first.edges.keys.toList(),
        const [FlowId('e2')],
      );

      stack.undo();
      expect(
        state.document.pages.first.edges.keys.toList(),
        const [FlowId('e1'), FlowId('e2')],
      );
    });
  });
}

class _FakeClock {
  _FakeClock(this._now);
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
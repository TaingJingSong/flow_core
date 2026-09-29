import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowController.applyLayout', () {
    test('layered layout assigns different y positions and is undoable', () {
      final c = FlowController.empty();
      addTearDown(c.dispose);

      final a = FlowNode(
        id: c.nextId(),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
      );
      final b = FlowNode(
        id: c.nextId(),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
      );
      c.addNode(a);
      c.addNode(b);
      c.addEdge(FlowEdge(
        id: c.nextId(),
        sourceNodeId: a.id,
        targetNodeId: b.id,
      ));

      final originalA = c.node(a.id)!.rect;
      final moved = c.applyLayout(const LayeredLayout());
      expect(moved, greaterThan(0));
      expect(c.node(a.id)!.rect.top < c.node(b.id)!.rect.top, isTrue);

      c.undo();
      expect(c.node(a.id)!.rect, originalA);
    });

    test('pinned nodes are not moved', () {
      final c = FlowController.empty();
      addTearDown(c.dispose);

      final a = FlowNode(
        id: c.nextId(),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(500, 500, 100, 40),
      );
      final b = FlowNode(
        id: c.nextId(),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
      );
      c.addNode(a);
      c.addNode(b);
      c.addEdge(FlowEdge(
        id: c.nextId(),
        sourceNodeId: a.id,
        targetNodeId: b.id,
      ));

      c.applyLayout(const LayeredLayout(), pinned: {a.id});
      expect(c.node(a.id)!.rect, FlowRect.fromLTWH(500, 500, 100, 40));
    });

    test('empty page returns 0', () {
      final c = FlowController.empty();
      addTearDown(c.dispose);
      expect(c.applyLayout(const LayeredLayout()), 0);
    });
  });
}
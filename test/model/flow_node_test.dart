import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowNode', () {
    test('equality with ports and data', () {
      final a = FlowNode(
        id: FlowId('n1'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
        ports: [FlowPort(name: 'in'), FlowPort(name: 'out')],
        data: {'x': 1, 'nested': {'y': 2}},
        tags: {'start'},
      );
      final b = FlowNode(
        id: FlowId('n1'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
        ports: [FlowPort(name: 'in'), FlowPort(name: 'out')],
        data: {'x': 1, 'nested': {'y': 2}},
        tags: {'start'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('portByName finds by name', () {
      const n = FlowNode(
        id: FlowId('n1'),
        type: 'rectangle',
        rect: FlowRect.zero,
        ports: [FlowPort(name: 'in'), FlowPort(name: 'out')],
      );
      expect(n.portByName('in')?.name, 'in');
      expect(n.portByName('missing'), isNull);
    });

    test('copyWith preserves fields', () {
      const n = FlowNode(
        id: FlowId('n1'),
        type: 'rectangle',
        rect: FlowRect.zero,
      );
      final moved = n.copyWith(
        rect: FlowRect.fromLTWH(10, 10, 100, 40),
      );
      expect(moved.id, n.id);
      expect(moved.type, 'rectangle');
      expect(moved.rect.left, 10);
    });
  });
}
import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowEdge', () {
    test('equality with waypoints and meta', () {
      const a = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
        waypoints: [FlowPoint(5, 5), FlowPoint(10, 10)],
        meta: {'label': 'yes'},
      );
      const b = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
        waypoints: [FlowPoint(5, 5), FlowPoint(10, 10)],
        meta: {'label': 'yes'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('connects', () {
      const e = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
      );
      expect(e.connects(const FlowId('a')), isTrue);
      expect(e.connects(const FlowId('b')), isTrue);
      expect(e.connects(const FlowId('c')), isFalse);
    });

    test('copyWith nulls port name', () {
      const e = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
        sourcePortName: 'out',
      );
      final cleared = e.copyWith(sourcePortName: null);
      expect(cleared.sourcePortName, isNull);
      expect(cleared.targetPortName, isNull);
    });
  });
}
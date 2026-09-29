import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowGroup', () {
    test('equality with children', () {
      final a = FlowGroup(
        id: FlowId('g1'),
        rect: FlowRect.fromLTWH(0, 0, 200, 200),
        childNodeIds: [FlowId('n1'), FlowId('n2')],
      );
      final b = FlowGroup(
        id: FlowId('g1'),
        rect: FlowRect.fromLTWH(0, 0, 200, 200),
        childNodeIds: [FlowId('n1'), FlowId('n2')],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
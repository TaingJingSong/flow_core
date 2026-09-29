import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowPage', () {
    test('empty has default layer', () {
      final page = FlowPage.empty(id: const FlowId('p1'));
      expect(page.layers, hasLength(1));
      expect(page.layers.values.first.name, 'Default');
    });

    test('nodes map is unmodifiable', () {
      final page = FlowPage.empty(id: const FlowId('p1'));
      expect(
        () => page.nodes[const FlowId('x')] = const FlowNode(
          id: FlowId('x'),
          type: 'rectangle',
          rect: FlowRect.zero,
        ),
        throwsUnsupportedError,
      );
    });

    test('equality', () {
      final a = FlowPage.empty(id: const FlowId('p1'));
      final b = FlowPage.empty(id: const FlowId('p1'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
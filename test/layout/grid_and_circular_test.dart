import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowLayoutInput inputFor(int count) => FlowLayoutInput(
      nodes: [
        for (var i = 0; i < count; i++)
          FlowLayoutNode(
            id: FlowId('n$i'),
            size: const FlowSize(100, 40),
          ),
      ],
      edges: const <FlowLayoutEdge>[],
    );

void main() {
  group('GridLayout', () {
    test('produces a grid with no overlaps', () {
      const engine = GridLayout();
      final r = engine.layout(inputFor(9));
      expect(r.rects, hasLength(9));
      final rects = r.rects.values.toList();
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].intersects(rects[j]), isFalse);
        }
      }
    });

    test('fixed column count', () {
      const engine = GridLayout(columns: 2);
      final r = engine.layout(inputFor(5));
      final n0 = r.rects[const FlowId('n0')]!;
      final n1 = r.rects[const FlowId('n1')]!;
      final n2 = r.rects[const FlowId('n2')]!;
      // n0 and n1 are in the same row.
      expect(n0.top, n1.top);
      // n2 is in the next row.
      expect(n2.top > n0.top, isTrue);
    });
  });

  group('CircularLayout', () {
    test('places nodes on a circle', () {
      const engine = CircularLayout();
      final r = engine.layout(inputFor(6));
      expect(r.rects, hasLength(6));
      final centers = [
        for (final rect in r.rects.values) rect.center,
      ];
      // All centers approximately equidistant from the mean.
      final meanX = centers.map((p) => p.x).reduce((a, b) => a + b) / centers.length;
      final meanY = centers.map((p) => p.y).reduce((a, b) => a + b) / centers.length;
      final distances = centers
          .map((p) => (p.x - meanX) * (p.x - meanX) + (p.y - meanY) * (p.y - meanY))
          .toList();
      final first = distances.first;
      for (final d in distances) {
        expect((d - first).abs() < 1e-3, isTrue);
      }
    });

    test('single node: no divide by zero', () {
      const engine = CircularLayout();
      final r = engine.layout(inputFor(1));
      expect(r.rects, hasLength(1));
    });

    test('empty: no crash', () {
      const engine = CircularLayout();
      final r = engine.layout(inputFor(0));
      expect(r.rects, isEmpty);
    });
  });
}
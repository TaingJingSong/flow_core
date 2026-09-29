import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowLayoutInput inputFor(
  List<(String, double, double)> nodes,
  List<(String, String)> edges, {
  FlowLayoutDirection direction = FlowLayoutDirection.topToBottom,
  FlowLayoutSpacing spacing = const FlowLayoutSpacing(),
}) =>
    FlowLayoutInput(
      nodes: [
        for (final (id, w, h) in nodes)
          FlowLayoutNode(id: FlowId(id), size: FlowSize(w, h)),
      ],
      edges: [
        for (final (s, t) in edges)
          FlowLayoutEdge(source: FlowId(s), target: FlowId(t)),
      ],
      direction: direction,
      spacing: spacing,
    );

void main() {
  group('LayeredLayout', () {
    test('empty input returns empty result', () {
      const engine = LayeredLayout();
      final r = engine.layout(const FlowLayoutInput(
        nodes: <FlowLayoutNode>[],
        edges: <FlowLayoutEdge>[],
      ));
      expect(r.rects, isEmpty);
    });

    test('linear chain: layers grow along direction', () {
      const engine = LayeredLayout();
      final r = engine.layout(inputFor(
        [('a', 100, 40), ('b', 100, 40), ('c', 100, 40)],
        [('a', 'b'), ('b', 'c')],
      ));
      final ya = r.rects[const FlowId('a')]!.top;
      final yb = r.rects[const FlowId('b')]!.top;
      final yc = r.rects[const FlowId('c')]!.top;
      expect(ya < yb, isTrue);
      expect(yb < yc, isTrue);
    });

    test('leftToRight grows along x', () {
      const engine = LayeredLayout();
      final r = engine.layout(inputFor(
        [('a', 100, 40), ('b', 100, 40), ('c', 100, 40)],
        [('a', 'b'), ('b', 'c')],
        direction: FlowLayoutDirection.leftToRight,
      ));
      final xa = r.rects[const FlowId('a')]!.left;
      final xb = r.rects[const FlowId('b')]!.left;
      final xc = r.rects[const FlowId('c')]!.left;
      expect(xa < xb, isTrue);
      expect(xb < xc, isTrue);
    });

    test('nodes in the same layer do not overlap', () {
      const engine = LayeredLayout();
      final r = engine.layout(inputFor(
        [
          ('a', 100, 40),
          ('b', 100, 40),
          ('c', 100, 40),
          ('d', 100, 40),
        ],
        [('a', 'b'), ('a', 'c'), ('a', 'd')],
      ));
      final rects = r.rects.values.toList();
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].intersects(rects[j]), isFalse,
              reason: 'rect $i overlaps rect $j');
        }
      }
    });

    test('deterministic for same input', () {
      const engine = LayeredLayout();
      final input = inputFor(
        [('a', 100, 40), ('b', 100, 40), ('c', 100, 40)],
        [('a', 'b'), ('a', 'c')],
      );
      final r1 = engine.layout(input);
      final r2 = engine.layout(input);
      expect(r1, r2);
    });

    test('handles cycles without infinite loop', () {
      const engine = LayeredLayout();
      final r = engine.layout(inputFor(
        [('a', 100, 40), ('b', 100, 40), ('c', 100, 40)],
        [('a', 'b'), ('b', 'c'), ('c', 'a')],
      ));
      expect(r.rects, hasLength(3));
    });

    test('pinned nodes keep their rects', () {
      const engine = LayeredLayout();
      final r = engine.layout(FlowLayoutInput(
        nodes: const [
          FlowLayoutNode(id: FlowId('a'), size: FlowSize(100, 40)),
          FlowLayoutNode(id: FlowId('b'), size: FlowSize(100, 40)),
        ],
        edges: const [
          FlowLayoutEdge(source: FlowId('a'), target: FlowId('b')),
        ],
        pinnedRects: {
          FlowId('a'): FlowRect.fromLTWH(500, 500, 100, 40),
        },
      ));
      expect(r.rects[const FlowId('a')], FlowRect.fromLTWH(500, 500, 100, 40));
    });

    test('bounds cover every node', () {
      const engine = LayeredLayout();
      final r = engine.layout(inputFor(
        [('a', 100, 40), ('b', 100, 40)],
        [('a', 'b')],
      ));
      final bounds = r.bounds!;
      for (final rect in r.rects.values) {
        expect(bounds.containsRect(rect), isTrue);
      }
    });
  });
}
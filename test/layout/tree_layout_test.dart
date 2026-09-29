import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowLayoutInput inputFor(
  List<String> ids,
  List<(String, String)> edges, {
  FlowLayoutDirection direction = FlowLayoutDirection.topToBottom,
}) =>
    FlowLayoutInput(
      nodes: [
        for (final id in ids)
          FlowLayoutNode(id: FlowId(id), size: const FlowSize(100, 40)),
      ],
      edges: [
        for (final (s, t) in edges)
          FlowLayoutEdge(source: FlowId(s), target: FlowId(t)),
      ],
      direction: direction,
    );

void main() {
  group('TreeLayout', () {
    test('single root with two children: root is centered over children', () {
      const engine = TreeLayout();
      final r = engine.layout(inputFor(
        ['root', 'l', 'r'],
        [('root', 'l'), ('root', 'r')],
      ));
      final root = r.rects[const FlowId('root')]!;
      final left = r.rects[const FlowId('l')]!;
      final right = r.rects[const FlowId('r')]!;

      expect(left.right <= right.left, isTrue);
      expect(root.centerX > left.centerX, isTrue);
      expect(root.centerX < right.centerX, isTrue);
    });

    test('children do not overlap', () {
      const engine = TreeLayout();
      final r = engine.layout(inputFor(
        ['r', 'a', 'b', 'c', 'd'],
        [('r', 'a'), ('r', 'b'), ('a', 'c'), ('a', 'd')],
      ));
      final rects = r.rects.values.toList();
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].intersects(rects[j]), isFalse);
        }
      }
    });

    test('forest: multiple roots packed side by side', () {
      const engine = TreeLayout();
      final r = engine.layout(inputFor(
        ['a', 'b', 'c', 'd'],
        [('a', 'b'), ('c', 'd')],
      ));
      final a = r.rects[const FlowId('a')]!;
      final c = r.rects[const FlowId('c')]!;
      // Both roots at same depth.
      expect(a.top, c.top);
      // Different subtrees: roots at different x.
      expect(a.left != c.left, isTrue);
    });

    test('leftToRight places deeper nodes further right', () {
      const engine = TreeLayout();
      final r = engine.layout(inputFor(
        ['a', 'b', 'c'],
        [('a', 'b'), ('b', 'c')],
        direction: FlowLayoutDirection.leftToRight,
      ));
      expect(
        r.rects[const FlowId('a')]!.left <
            r.rects[const FlowId('b')]!.left,
        isTrue,
      );
      expect(
        r.rects[const FlowId('b')]!.left <
            r.rects[const FlowId('c')]!.left,
        isTrue,
      );
    });

    test('deterministic', () {
      const engine = TreeLayout();
      final input = inputFor(
        ['a', 'b', 'c', 'd'],
        [('a', 'b'), ('a', 'c'), ('c', 'd')],
      );
      expect(engine.layout(input), engine.layout(input));
    });

    test('cycle falls back gracefully', () {
      const engine = TreeLayout();
      final r = engine.layout(inputFor(
        ['a', 'b', 'c'],
        [('a', 'b'), ('b', 'c'), ('c', 'a')],
      ));
      expect(r.rects, hasLength(3));
    });
  });
}
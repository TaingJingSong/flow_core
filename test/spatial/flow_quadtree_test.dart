import 'dart:math';

import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowQuadtree', () {
    test('empty tree has no items', () {
      final q = FlowQuadtree<int>.empty();
      expect(q.isEmpty, isTrue);
      expect(q.length, 0);
      expect(q.query(FlowRect.fromLTWH(0, 0, 100, 100)), isEmpty);
    });

    test('insert and query finds overlapping items', () {
      final q = FlowQuadtree<int>.empty();
      q.insert(1, FlowRect.fromLTWH(0, 0, 10, 10));
      q.insert(2, FlowRect.fromLTWH(20, 20, 10, 10));
      q.insert(3, FlowRect.fromLTWH(200, 200, 10, 10));

      final hits = q.query(FlowRect.fromLTWH(0, 0, 50, 50));
      expect(hits.toSet(), {1, 2});
    });

    test('query returns items touching the range boundary', () {
      final q = FlowQuadtree<int>.empty();
      q.insert(1, FlowRect.fromLTWH(0, 0, 10, 10));
      final hits = q.query(FlowRect.fromLTWH(5, 5, 5, 5));
      expect(hits, contains(1));
    });

    test('query excludes items fully outside the range', () {
      final q = FlowQuadtree<int>.empty();
      q.insert(1, FlowRect.fromLTWH(0, 0, 10, 10));
      final hits = q.query(FlowRect.fromLTWH(100, 100, 10, 10));
      expect(hits, isEmpty);
    });

    test('expands when item is out of bounds', () {
      final q = FlowQuadtree<int>.empty();
      q.insert(1, FlowRect.fromLTWH(0, 0, 10, 10));
      q.insert(2, FlowRect.fromLTWH(1000, 1000, 10, 10));
      final hits = q.query(FlowRect.fromLTWH(990, 990, 40, 40));
      expect(hits, contains(2));
      final firstHits = q.query(FlowRect.fromLTWH(-1, -1, 12, 12));
      expect(firstHits, contains(1));
    });

    test('clear resets', () {
      final q = FlowQuadtree<int>.empty();
      q.insert(1, FlowRect.fromLTWH(0, 0, 10, 10));
      q.clear();
      expect(q.isEmpty, isTrue);
      expect(q.query(FlowRect.fromLTWH(-1, -1, 100, 100)), isEmpty);
    });

    test('fuzz: quadtree matches linear scan', () {
      final rng = Random(42);
      final entries = <(int, FlowRect)>[];
      for (var i = 0; i < 1000; i++) {
        final x = rng.nextDouble() * 2000 - 500;
        final y = rng.nextDouble() * 2000 - 500;
        final w = rng.nextDouble() * 60 + 4;
        final h = rng.nextDouble() * 60 + 4;
        entries.add((i, FlowRect.fromLTWH(x, y, w, h)));
      }

      final q = FlowQuadtree<int>.empty(capacity: 6, maxDepth: 8);
      for (final e in entries) {
        q.insert(e.$1, e.$2);
      }
      expect(q.length, entries.length);

      for (var t = 0; t < 200; t++) {
        final x = rng.nextDouble() * 2000 - 500;
        final y = rng.nextDouble() * 2000 - 500;
        final w = rng.nextDouble() * 300;
        final h = rng.nextDouble() * 300;
        final range = FlowRect.fromLTWH(x, y, w, h);

        final expected = <int>{
          for (final e in entries)
            if (e.$2.intersects(range)) e.$1,
        };
        final actual = q.query(range).toSet();
        expect(actual, expected, reason: 'query at $range');
      }
    });

    test('fuzz: incremental insertion and expansion', () {
      final rng = Random(7);
      final q = FlowQuadtree<int>.empty();
      final all = <(int, FlowRect)>[];
      for (var i = 0; i < 500; i++) {
        // Deliberately spread far apart to force root expansion.
        final x = rng.nextDouble() * 100000 - 50000;
        final y = rng.nextDouble() * 100000 - 50000;
        final r = FlowRect.fromLTWH(x, y, 10, 10);
        q.insert(i, r);
        all.add((i, r));
      }
      for (var t = 0; t < 100; t++) {
        final x = rng.nextDouble() * 100000 - 50000;
        final y = rng.nextDouble() * 100000 - 50000;
        final range = FlowRect.fromLTWH(x, y, 200, 200);
        final expected = <int>{
          for (final e in all)
            if (e.$2.intersects(range)) e.$1,
        };
        final actual = q.query(range).toSet();
        expect(actual, expected);
      }
    });
  });
}
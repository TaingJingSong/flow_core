import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowRect', () {
    test('contains point', () {
      final r = FlowRect.fromLTWH(0, 0, 10, 10);
      expect(r.contains(const FlowPoint(5, 5)), isTrue);
      expect(r.contains(const FlowPoint(15, 5)), isFalse);
    });

    test('intersects', () {
      final a = FlowRect.fromLTWH(0, 0, 10, 10);
      final b = FlowRect.fromLTWH(5, 5, 10, 10);
      final c = FlowRect.fromLTWH(20, 20, 5, 5);
      expect(a.intersects(b), isTrue);
      expect(a.intersects(c), isFalse);
    });

    test('union', () {
      final a = FlowRect.fromLTWH(0, 0, 10, 10);
      final b = FlowRect.fromLTWH(5, 5, 10, 10);
      expect(a.union(b), FlowRect.fromLTWH(0, 0, 15, 15));
    });

    test('fromPoints', () {
      const a = FlowPoint(10, 20);
      const b = FlowPoint(0, 5);
      expect(FlowRect.fromPoints(a, b), FlowRect.fromLTWH(0, 5, 10, 15));
    });
  });
}
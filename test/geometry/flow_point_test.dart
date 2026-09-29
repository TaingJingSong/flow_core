import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowPoint', () {
    test('addition', () {
      expect(const FlowPoint(1, 2) + const FlowPoint(3, 4), const FlowPoint(4, 6));
    });

    test('subtraction', () {
      expect(const FlowPoint(5, 5) - const FlowPoint(2, 1), const FlowPoint(3, 4));
    });

    test('distance', () {
      const a = FlowPoint(0, 0);
      const b = FlowPoint(3, 4);
      expect(a.distanceTo(b), 5.0);
    });

    test('equality', () {
      expect(const FlowPoint(1, 2), const FlowPoint(1, 2));
      expect(const FlowPoint(1, 2).hashCode, const FlowPoint(1, 2).hashCode);
    });

    test('lerp', () {
      const a = FlowPoint(0, 0);
      const b = FlowPoint(10, 20);
      expect(a.lerp(b, 0.5), const FlowPoint(5, 10));
    });
  });
}
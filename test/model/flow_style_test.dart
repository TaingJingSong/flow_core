import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowStyle', () {
    test('default equality', () {
      expect(const FlowStyle(), const FlowStyle());
    });

    test('copyWith respects sentinel for nullables', () {
      const s = FlowStyle(fillColor: FlowColor.redColor);
      final s2 = s.copyWith(fillColor: null);
      expect(s2.fillColor, isNull);
      final s3 = s.copyWith();
      expect(s3.fillColor, FlowColor.redColor);
    });

    test('merge prefers other', () {
      const a = FlowStyle(fillColor: FlowColor.redColor, cornerRadius: 4);
      const b = FlowStyle(fillColor: FlowColor.blueColor);
      final merged = a.merge(b);
      expect(merged.fillColor, FlowColor.blueColor);
      expect(merged.cornerRadius, 4);
    });

    test('dash pattern equality', () {
      const a = FlowStyle(strokeDashPattern: [4, 2]);
      const b = FlowStyle(strokeDashPattern: [4, 2]);
      const c = FlowStyle(strokeDashPattern: [4, 3]);
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
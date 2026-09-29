import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowColor', () {
    test('fromARGB round trips', () {
      const c = FlowColor.fromARGB(0x80, 0x12, 0x34, 0x56);
      expect(c.alpha, 0x80);
      expect(c.red, 0x12);
      expect(c.green, 0x34);
      expect(c.blue, 0x56);
    });

    test('equality and hashCode', () {
      const a = FlowColor(0xFF112233);
      const b = FlowColor(0xFF112233);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('withOpacity clamps', () {
      expect(FlowColor.black.withOpacity(2.0).alpha, 255);
      expect(FlowColor.black.withOpacity(-1.0).alpha, 0);
    });
  });
}
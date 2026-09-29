import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowLayoutRegistry', () {
    test('default registry ships four engines', () {
      final r = FlowLayoutRegistry();
      expect(r.byId('layered'), isA<LayeredLayout>());
      expect(r.byId('tree'), isA<TreeLayout>());
      expect(r.byId('grid'), isA<GridLayout>());
      expect(r.byId('circular'), isA<CircularLayout>());
    });

    test('fallback is layered', () {
      final r = FlowLayoutRegistry();
      expect(r.fallback, isA<LayeredLayout>());
    });

    test('custom engines can be registered', () {
      final r = FlowLayoutRegistry();
      r.register(const GridLayout());
      expect(r.byId('grid'), isA<GridLayout>());
    });
  });
}
import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowRouterRegistry', () {
    test('default registry ships three routers', () {
      final reg = FlowRouterRegistry();
      expect(reg.byId('straight'), isNotNull);
      expect(reg.byId('orthogonal'), isNotNull);
      expect(reg.byId('bezier'), isNotNull);
    });

    test('routerFor maps enum to router', () {
      final reg = FlowRouterRegistry();
      expect(reg.routerFor(FlowEdgeRouting.straight), isA<StraightRouter>());
      expect(reg.routerFor(FlowEdgeRouting.orthogonal), isA<OrthogonalRouter>());
      expect(reg.routerFor(FlowEdgeRouting.bezier), isA<BezierRouter>());
      expect(
        reg.routerFor(FlowEdgeRouting.obstacleAvoiding),
        isA<OrthogonalRouter>(),
      );
    });

    test('unknown router falls back to straight', () {
      final reg = FlowRouterRegistry();
      reg.unregister('straight');
      // After unregistering straight, the fallback is still "straight",
      // but the map has no such router, so it returns a fresh
      // StraightRouter via the last-ditch fallback.
      final r = reg.routerFor(FlowEdgeRouting.straight);
      expect(r, isA<StraightRouter>());
    });

    test('custom routers can be added', () {
      final reg = FlowRouterRegistry();
      reg.register(const StraightRouter());
      expect(reg.routers, isNotEmpty);
    });
  });
}
import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowNode node(String id, double x, double y, double w, double h,
        {List<FlowPort> ports = const []}) =>
    FlowNode(
      id: FlowId(id),
      type: 'rectangle',
      rect: FlowRect.fromLTWH(x, y, w, h),
      ports: ports,
    );

FlowEdge edge(String id, String from, String to,
        {String? fromPort, String? toPort}) =>
    FlowEdge(
      id: FlowId(id),
      sourceNodeId: FlowId(from),
      targetNodeId: FlowId(to),
      sourcePortName: fromPort,
      targetPortName: toPort,
    );

FlowPage pageOf(List<FlowNode> nodes, List<FlowEdge> edges) => FlowPage(
      id: const FlowId('p'),
      name: 'P',
      nodes: {for (final n in nodes) n.id: n},
      edges: {for (final e in edges) e.id: e},
    );

void main() {
  group('OrthogonalRouter', () {
    test('horizontal to horizontal produces a Z-shape', () {
      final n1 = node('a', 0, 0, 100, 40, ports: const [
        FlowPort(name: 'out', side: FlowPortSide.right),
      ]);
      final n2 = node('b', 300, 200, 100, 40, ports: const [
        FlowPort(name: 'in', side: FlowPortSide.left),
      ]);
      final e = edge('e1', 'a', 'b', fromPort: 'out', toPort: 'in');
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const OrthogonalRouter());
      // Path should be a Z with 4 points after cleanup.
      expect(path.points.length, 4);

      // Every segment must be axis-aligned.
      for (var i = 0; i < path.points.length - 1; i++) {
        final a = path.points[i];
        final b = path.points[i + 1];
        final dx = (b.x - a.x).abs();
        final dy = (b.y - a.y).abs();
        expect(dx < 1e-6 || dy < 1e-6, isTrue,
            reason: 'segment $i is not axis-aligned: $a -> $b');
      }
    });

    test('horizontal to vertical produces an L-shape', () {
      final n1 = node('a', 0, 0, 100, 40, ports: const [
        FlowPort(name: 'out', side: FlowPortSide.right),
      ]);
      final n2 = node('b', 300, 200, 100, 40, ports: const [
        FlowPort(name: 'in', side: FlowPortSide.top),
      ]);
      final e = edge('e1', 'a', 'b', fromPort: 'out', toPort: 'in');
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const OrthogonalRouter());
      expect(path.points.length, 3);

      for (var i = 0; i < path.points.length - 1; i++) {
        final a = path.points[i];
        final b = path.points[i + 1];
        final dx = (b.x - a.x).abs();
        final dy = (b.y - a.y).abs();
        expect(dx < 1e-6 || dy < 1e-6, isTrue);
      }
    });

    test('vertical to vertical produces a Z-shape', () {
      final n1 = node('a', 0, 0, 100, 40, ports: const [
        FlowPort(name: 'out', side: FlowPortSide.bottom),
      ]);
      final n2 = node('b', 300, 200, 100, 40, ports: const [
        FlowPort(name: 'in', side: FlowPortSide.top),
      ]);
      final e = edge('e1', 'a', 'b', fromPort: 'out', toPort: 'in');
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const OrthogonalRouter());
      expect(path.points.length, 4);

      for (var i = 0; i < path.points.length - 1; i++) {
        final a = path.points[i];
        final b = path.points[i + 1];
        final dx = (b.x - a.x).abs();
        final dy = (b.y - a.y).abs();
        expect(dx < 1e-6 || dy < 1e-6, isTrue);
      }
    });

    test('waypoints are honored verbatim', () {
      final n1 = node('a', 0, 0, 100, 40);
      final n2 = node('b', 400, 400, 100, 40);
      final e = FlowEdge(
        id: const FlowId('e1'),
        sourceNodeId: const FlowId('a'),
        targetNodeId: const FlowId('b'),
        waypoints: const [FlowPoint(200, 400)],
      );
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const OrthogonalRouter());
      expect(path.points, contains(const FlowPoint(200, 400)));
    });
  });
}
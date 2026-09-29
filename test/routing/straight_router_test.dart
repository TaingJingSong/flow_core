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
        {String? fromPort, String? toPort, List<FlowPoint> waypoints = const []}) =>
    FlowEdge(
      id: FlowId(id),
      sourceNodeId: FlowId(from),
      targetNodeId: FlowId(to),
      sourcePortName: fromPort,
      targetPortName: toPort,
      waypoints: waypoints,
    );

FlowPage pageOf(List<FlowNode> nodes, List<FlowEdge> edges) => FlowPage(
      id: const FlowId('p'),
      name: 'P',
      nodes: {for (final n in nodes) n.id: n},
      edges: {for (final e in edges) e.id: e},
    );

void main() {
  group('StraightRouter', () {
    test('no waypoints: two-point line', () {
      final n1 = node('a', 0, 0, 100, 40);
      final n2 = node('b', 200, 0, 100, 40);
      final e = edge('e1', 'a', 'b');
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const StraightRouter());
      expect(path.points, hasLength(2));
      expect(path.cubics, isEmpty);
    });

    test('with waypoints: polyline through them', () {
      final n1 = node('a', 0, 0, 100, 40);
      final n2 = node('b', 300, 300, 100, 40);
      final e = edge('e1', 'a', 'b',
          waypoints: const [FlowPoint(400, 20), FlowPoint(400, 300)]);
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const StraightRouter());
      expect(path.points, hasLength(4));
      expect(path.points[1], const FlowPoint(400, 20));
      expect(path.points[2], const FlowPoint(400, 300));
    });

    test('port anchors are honored', () {
      final n1 = node('a', 0, 0, 100, 40, ports: const [
        FlowPort(name: 'out', side: FlowPortSide.right),
      ]);
      final n2 = node('b', 200, 0, 100, 40, ports: const [
        FlowPort(name: 'in', side: FlowPortSide.left),
      ]);
      final e = edge('e1', 'a', 'b', fromPort: 'out', toPort: 'in');
      final page = pageOf([n1, n2], [e]);

      final path = routeEdge(e, page, router: const StraightRouter());
      expect(path.points.first, const FlowPoint(100, 20));
      expect(path.points.last, const FlowPoint(200, 20));
    });
  });
}
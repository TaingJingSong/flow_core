import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('BezierRouter', () {
    test('produces one cubic and a flattened polyline', () {
      final n1 = FlowNode(
        id: FlowId('a'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
        ports: [FlowPort(name: 'out', side: FlowPortSide.right)],
      );
      final n2 = FlowNode(
        id: FlowId('b'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(300, 100, 100, 40),
        ports: [FlowPort(name: 'in', side: FlowPortSide.left)],
      );
      const e = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
        sourcePortName: 'out',
        targetPortName: 'in',
      );
      final page = FlowPage(
        id: const FlowId('p'),
        name: 'P',
        nodes: {n1.id: n1, n2.id: n2},
        edges: {e.id: e},
      );

      final path = routeEdge(e, page, router: const BezierRouter());
      expect(path.cubics, hasLength(1));
      expect(path.points.length, 25); // 24 subdivisions + 1
      expect(path.points.first, path.cubics.first.p1);
      expect(path.points.last, path.cubics.first.p2);
    });

    test('cubic evaluate hits endpoints exactly', () {
      const c = FlowCubic(
        FlowPoint(0, 0),
        FlowPoint(50, 0),
        FlowPoint(100, 50),
        FlowPoint(150, 50),
      );
      expect(c.evaluate(0), const FlowPoint(0, 0));
      expect(c.evaluate(1), const FlowPoint(150, 50));
    });

    test('waypoints fall back to straight polyline', () {
      final n1 = FlowNode(
        id: FlowId('a'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(0, 0, 100, 40),
      );
      final n2 = FlowNode(
        id: FlowId('b'),
        type: 'rectangle',
        rect: FlowRect.fromLTWH(400, 400, 100, 40),
      );
      const e = FlowEdge(
        id: FlowId('e1'),
        sourceNodeId: FlowId('a'),
        targetNodeId: FlowId('b'),
        waypoints: [FlowPoint(200, 400)],
      );
      final page = FlowPage(
        id: const FlowId('p'),
        name: 'P',
        nodes: {n1.id: n1, n2.id: n2},
        edges: {e.id: e},
      );

      final path = routeEdge(e, page, router: const BezierRouter());
      expect(path.cubics, isEmpty);
      expect(path.points, contains(const FlowPoint(200, 400)));
    });
  });
}
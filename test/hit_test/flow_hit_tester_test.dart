import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowNode node(
  String id, {
  double x = 0,
  double y = 0,
  double w = 100,
  double h = 40,
  int zIndex = 0,
  List<FlowPort> ports = const <FlowPort>[],
}) =>
    FlowNode(
      id: FlowId(id),
      type: 'rectangle',
      rect: FlowRect.fromLTWH(x, y, w, h),
      ports: ports,
      zIndex: zIndex,
    );

FlowEdge edge(
  String id,
  String from,
  String to, {
  List<FlowPoint> waypoints = const <FlowPoint>[],
}) =>
    FlowEdge(
      id: FlowId(id),
      sourceNodeId: FlowId(from),
      targetNodeId: FlowId(to),
      waypoints: waypoints,
    );

FlowPage pageOf({
  Iterable<FlowNode> nodes = const <FlowNode>[],
  Iterable<FlowEdge> edges = const <FlowEdge>[],
}) =>
    FlowPage(
      id: const FlowId('p1'),
      name: 'P',
      nodes: {for (final n in nodes) n.id: n},
      edges: {for (final e in edges) e.id: e},
    );

void main() {
  group('FlowHitTester', () {
    test('point inside a node is hit', () {
      final page = pageOf(nodes: [node('a')]);
      final t = FlowHitTester(page: page);
      final r = t.hitTestPoint(const FlowPoint(50, 20));
      expect(r.nodes.map((n) => n.id.value).toList(), ['a']);
    });

    test('point outside any node returns empty', () {
      final page = pageOf(nodes: [node('a')]);
      final t = FlowHitTester(page: page);
      final r = t.hitTestPoint(const FlowPoint(500, 500));
      expect(r.isEmpty, isTrue);
    });

    test('topmost node wins first in order', () {
      final page = pageOf(nodes: [
        node('low', zIndex: 0),
        node('high', zIndex: 10),
      ]);
      final t = FlowHitTester(page: page);
      final r = t.hitTestPoint(const FlowPoint(50, 20));
      expect(r.nodes.first.id.value, 'high');
      expect(r.nodes.map((n) => n.id.value).toList(), ['high', 'low']);
    });

    test('edge is only reported when no node is hit', () {
      final page = pageOf(
        nodes: [node('a', x: 0, y: 0), node('b', x: 200, y: 0)],
        edges: [edge('e1', 'a', 'b')],
      );
      final t = FlowHitTester(page: page);

      // Middle of the edge — should not be over either node.
      final r = t.hitTestPoint(const FlowPoint(150, 20));
      expect(r.nodes, isEmpty);
      expect(r.edges.map((e) => e.id.value), ['e1']);
    });

    test('point over a node on top of an edge reports only the node', () {
      final page = pageOf(
        nodes: [node('a'), node('b', x: 200)],
        edges: [edge('e1', 'a', 'b')],
      );
      final t = FlowHitTester(page: page);
      final r = t.hitTestPoint(const FlowPoint(50, 20));
      expect(r.nodes, isNotEmpty);
      expect(r.edges, isEmpty);
    });

    test('port is hit within portRadius', () {
      final page = pageOf(nodes: [
        node('a', ports: const [
          FlowPort(name: 'in', side: FlowPortSide.left, kind: FlowPortKind.input),
        ]),
      ]);
      final t = FlowHitTester(page: page, portRadius: 10);
      final r = t.hitTestPoint(const FlowPoint(2, 20));
      expect(r.ports, hasLength(1));
      expect(r.ports.first.portName, 'in');
    });

    test('port is not hit beyond portRadius', () {
      final page = pageOf(nodes: [
        node('a', ports: const [
          FlowPort(name: 'in', side: FlowPortSide.left, kind: FlowPortKind.input),
        ]),
      ]);
      final t = FlowHitTester(page: page, portRadius: 4);
      final r = t.hitTestPoint(const FlowPoint(-10, 20));
      expect(r.ports, isEmpty);
    });

    test('non-connectable ports are skipped', () {
      final page = pageOf(nodes: [
        node('a', ports: const [
          FlowPort(
            name: 'in',
            side: FlowPortSide.left,
            isConnectable: false,
          ),
        ]),
      ]);
      final t = FlowHitTester(page: page);
      final r = t.hitTestPoint(const FlowPoint(2, 20));
      expect(r.ports, isEmpty);
    });

    test('rect hit test returns intersecting nodes and edges', () {
      final page = pageOf(
        nodes: [
          node('a', x: 0, y: 0),
          node('b', x: 200, y: 0),
          node('c', x: 500, y: 500),
        ],
        edges: [edge('e1', 'a', 'b'), edge('e2', 'b', 'c')],
      );
      final t = FlowHitTester(page: page);
      final r = t.hitTestRect(FlowRect.fromLTWH(-5, -5, 220, 60));
      expect(r.nodes.map((n) => n.id.value).toSet(), {'a', 'b'});
      expect(r.edges.map((e) => e.id.value).toSet(), {'e1'});
    });

    test('rect hit test skips invisible nodes', () {
      final page = pageOf(nodes: [
        node('a'),
        node('b', x: 200).copyWith(visible: false),
      ]);
      final t = FlowHitTester(page: page);
      final r = t.hitTestRect(FlowRect.fromLTWH(-10, -10, 500, 500));
      expect(r.nodes.map((n) => n.id.value), ['a']);
    });

    test('uses spatial index when provided', () {
      final page = pageOf(
        nodes: [node('a'), node('b', x: 200)],
        edges: [edge('e1', 'a', 'b')],
      );
      final index = FlowSpatialIndex.build(page);
      final t = FlowHitTester(page: page, index: index);
      final r = t.hitTestPoint(const FlowPoint(50, 20));
      expect(r.nodes.first.id.value, 'a');
    });

    test('edge waypoints are honored in hit testing', () {
      final page = pageOf(
        nodes: [node('a', x: 0, y: 0), node('b', x: 200, y: 200)],
        edges: [
          edge('e1', 'a', 'b', waypoints: const [
            FlowPoint(300, 20),
            FlowPoint(300, 220),
          ]),
        ],
      );
      final t = FlowHitTester(page: page, tolerance: 4);
      final r = t.hitTestPoint(const FlowPoint(300, 100));
      expect(r.edges, hasLength(1));
      expect(r.edges.first.id.value, 'e1');
    });
  });
}
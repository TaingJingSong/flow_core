import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

import '../fixtures/dot_fixtures.dart' as dot;
import '../fixtures/drawio_fixtures.dart' as drawio;
import '../fixtures/mermaid_fixtures.dart' as mermaid;

/// Structural comparison of two graphs, ignoring order-only differences.
void assertGraphsEquivalent(FlowGraph a, FlowGraph b, {String? reason}) {
  final r = reason == null ? '' : ' ($reason)';

  expect(b.nodes.keys.toSet(), a.nodes.keys.toSet(),
      reason: 'node ids differ$r');

  for (final id in a.nodes.keys) {
    final na = a.nodes[id]!;
    final nb = b.nodes[id]!;
    expect(nb.label, na.label, reason: 'label of $id differs$r');
    expect(nb.shape, na.shape, reason: 'shape of $id differs$r');
  }

  expect(b.edges.length, a.edges.length, reason: 'edge count differs$r');
  final pairsA = <String>{
    for (final e in a.edges.values) '${e.source}->${e.target}',
  };
  final pairsB = <String>{
    for (final e in b.edges.values) '${e.source}->${e.target}',
  };
  expect(pairsB, pairsA, reason: 'edge pairs differ$r');

  expect(b.groups.keys.toSet(), a.groups.keys.toSet(),
      reason: 'group ids differ$r');
}

void main() {
  const mermaidFormat = MermaidFlowchartFormat();
  const dotFormat = GraphvizDotFormat();
  const drawioFormat = DrawioXmlFormat();

  group('Mermaid round-trip', () {
    for (final f in mermaid.allFixtures) {
      test(f.name, () async {
        final g1 = await mermaidFormat.parse(f.source);
        final s = await mermaidFormat.emit(g1);
        final g2 = await mermaidFormat.parse(s);
        assertGraphsEquivalent(g1, g2, reason: f.name);
      });
    }
  });

  group('DOT round-trip', () {
    for (final f in dot.allFixtures) {
      test(f.name, () async {
        final g1 = await dotFormat.parse(f.source);
        final s = await dotFormat.emit(g1);
        final g2 = await dotFormat.parse(s);
        assertGraphsEquivalent(g1, g2, reason: f.name);
      });
    }
  });

  group('draw.io round-trip', () {
    for (final f in drawio.allFixtures) {
      test(f.name, () async {
        final g1 = await drawioFormat.parse(f.source);
        final s = await drawioFormat.emit(g1);
        final g2 = await drawioFormat.parse(s);
        assertGraphsEquivalent(g1, g2, reason: f.name);
        // Positions are the whole point of draw.io: verify they survive.
        for (final id in g1.nodes.keys) {
          expect(g2.nodes[id]!.rect, g1.nodes[id]!.rect,
              reason: 'rect of $id differs (${f.name})');
        }
      });
    }
  });
}
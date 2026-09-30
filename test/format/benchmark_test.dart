@Tags(['benchmark'])
library;

import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

/// Generates a Mermaid flowchart with [n] nodes and roughly n edges.
String generateMermaid(int n) {
  final b = StringBuffer('flowchart TD\n');
  for (var i = 0; i < n; i++) {
    b.writeln('    N$i["Node $i"]');
  }
  for (var i = 0; i < n - 1; i++) {
    b.writeln('    N$i --> N${i + 1}');
    if (i > 2 && i % 3 == 0) {
      b.writeln('    N${i - 2} --> N$i');
    }
  }
  return b.toString();
}

/// Generates a DOT digraph with [n] nodes and roughly n edges.
String generateDot(int n) {
  final b = StringBuffer('digraph G {\n');
  b.writeln('  rankdir=TB;');
  for (var i = 0; i < n; i++) {
    b.writeln('  N$i [label="Node $i"];');
  }
  for (var i = 0; i < n - 1; i++) {
    b.writeln('  N$i -> N${i + 1};');
  }
  b.writeln('}');
  return b.toString();
}

void main() {
  const mermaidFormat = MermaidFlowchartFormat();
  const dotFormat = GraphvizDotFormat();

  group('Benchmarks (run with: dart test -t benchmark)', () {
    test('parse 1000-node Mermaid', () async {
      final source = generateMermaid(1000);
      final sw = Stopwatch()..start();
      final graph = await mermaidFormat.parse(source);
      sw.stop();
      // ignore: avoid_print
      print('Mermaid parse: ${sw.elapsedMilliseconds} ms');
      expect(graph.nodes.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('parse 1000-node DOT', () async {
      final source = generateDot(1000);
      final sw = Stopwatch()..start();
      final graph = await dotFormat.parse(source);
      sw.stop();
      // ignore: avoid_print
      print('DOT parse: ${sw.elapsedMilliseconds} ms');
      expect(graph.nodes.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('layout 1000-node layered graph', () {
      final nodes = <FlowLayoutNode>[
        for (var i = 0; i < 1000; i++)
          FlowLayoutNode(
            id: FlowId('N$i'),
            size: const FlowSize(120, 50),
          ),
      ];
      final edges = <FlowLayoutEdge>[
        for (var i = 0; i < 999; i++)
          FlowLayoutEdge(source: FlowId('N$i'), target: FlowId('N${i + 1}')),
      ];
      const engine = LayeredLayout();

      final sw = Stopwatch()..start();
      final result = engine.layout(FlowLayoutInput(nodes: nodes, edges: edges));
      sw.stop();
      // ignore: avoid_print
      print('Layered layout (1000 nodes): ${sw.elapsedMilliseconds} ms');
      expect(result.rects.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('full pipeline: Mermaid parse + layout + document', () async {
      final registry = FlowFormatRegistry();
      registry.register(const MermaidFlowchartFormat());
      final importer = FlowImportPipeline(registry: registry);
      final source = generateMermaid(500);

      final sw = Stopwatch()..start();
      final doc = await importer.importAs(source, 'mermaid');
      sw.stop();
      // ignore: avoid_print
      print('Mermaid pipeline (500 nodes): ${sw.elapsedMilliseconds} ms');
      expect(doc.firstPage!.nodes.length, 500);
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('serialization round-trip 1000 nodes', () async {
      final registry = FlowFormatRegistry();
      registry.register(const MermaidFlowchartFormat());
      final importer = FlowImportPipeline(registry: registry);
      final source = generateMermaid(1000);
      final doc = await importer.importAs(source, 'mermaid');

      const codec = FlowJsonCodec();
      final sw = Stopwatch()..start();
      final s = codec.encodeToString(doc);
      final restored = codec.decodeFromString(s);
      sw.stop();
      // ignore: avoid_print
      print('JSON round-trip (1000 nodes): ${sw.elapsedMilliseconds} ms');
      expect(restored.firstPage!.nodes.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}

import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

const simpleDigraph = '''
digraph G {
  rankdir=LR;
  A [shape=box, label="Start"];
  B [shape=ellipse, label="End"];
  A -> B [label="next"];
}
''';

const clustered = '''
digraph Flow {
  subgraph cluster_exit {
    label="Exit";
    E [label="Exit case"];
    EV [label="Exit case versions"];
  }
  subgraph cluster_finance {
    label="Finance";
    F [label="Final pay"];
    FV [label="Final pay versions"];
  }
  E -> EV;
  E -> F;
  EV -> FV;
  F -> FV;
}
''';

const undirected = '''
graph G {
  A -- B -- C;
  A -- C;
}
''';

const chained = '''
digraph G {
  A -> B -> C -> D;
}
''';

const defaultsTest = '''
digraph G {
  node [shape=box, style=filled, fillcolor="#dae8fc"];
  edge [style=dashed];
  A -> B;
  C -> D;
}
''';

const portsTest = '''
digraph G {
  A:out -> B:in;
  A:out -> C:in;
}
''';

const subgraphEndpoint = '''
digraph G {
  { A B } -> C;
}
''';

const htmlLabel = '''
digraph G {
  A [label=<Hello <B>World</B>>];
  A -> B;
}
''';

void main() {
  const format = GraphvizDotFormat();

  group('GraphvizDotFormat.canParse', () {
    test('digraph', () {
      expect(format.canParse('digraph G { }'), isTrue);
    });
    test('graph', () {
      expect(format.canParse('graph G { }'), isTrue);
    });
    test('strict', () {
      expect(format.canParse('strict digraph G { }'), isTrue);
    });
    test('rejects mermaid', () {
      expect(format.canParse('flowchart TD\nA-->B'), isFalse);
    });
    test('rejects random text', () {
      expect(format.canParse('hello world'), isFalse);
    });
  });

  group('GraphvizDotFormat.parse', () {
    test('simple digraph: nodes and edges', () async {
      final g = await format.parse(simpleDigraph);
      expect(g.nodes.keys.toSet(), {'A', 'B'});
      expect(g.edges, hasLength(1));
      expect(g.suggestedDirection, FlowLayoutDirection.leftToRight);
    });

    test('labels and shapes mapped', () async {
      final g = await format.parse(simpleDigraph);
      expect(g.nodes['A']!.label, 'Start');
      expect(g.nodes['A']!.shape, 'rectangle');
      expect(g.nodes['B']!.label, 'End');
      expect(g.nodes['B']!.shape, 'ellipse');
    });

    test('edge labels', () async {
      final g = await format.parse(simpleDigraph);
      final e = g.edges.values.first;
      expect(e.label, 'next');
      expect(e.targetArrow, FlowArrowHead.filledArrow);
    });

    test('undirected graph edges', () async {
      final g = await format.parse(undirected);
      expect(g.meta['directed'], isFalse);
      expect(g.edges, hasLength(3));
      for (final e in g.edges.values) {
        expect(e.targetArrow, FlowArrowHead.filledArrow);
      }
    });

    test('chained edges', () async {
      final g = await format.parse(chained);
      expect(g.edges, hasLength(3));
      expect(g.nodes, hasLength(4));
      final pairs = {
        for (final e in g.edges.values) '${e.source}->${e.target}',
      };
      expect(pairs, {'A->B', 'B->C', 'C->D'});
    });

    test('cluster subgraphs become groups', () async {
      final g = await format.parse(clustered);
      expect(g.groups.keys.toSet(), {'cluster_exit', 'cluster_finance'});
      expect(g.groups['cluster_exit']!.label, 'Exit');
      expect(g.groups['cluster_exit']!.nodeIds.toSet(), {'E', 'EV'});
      expect(g.groups['cluster_finance']!.label, 'Finance');
      expect(g.groups['cluster_finance']!.nodeIds.toSet(), {'F', 'FV'});
      expect(g.nodes['E']!.groupId, 'cluster_exit');
      expect(g.nodes['F']!.groupId, 'cluster_finance');
    });

    test('default node attrs apply', () async {
      final g = await format.parse(defaultsTest);
      for (final n in g.nodes.values) {
        expect(n.shape, 'rectangle');
        expect(n.meta['fillcolor'], '#dae8fc');
      }
    });

    test('default edge attrs apply', () async {
      final g = await format.parse(defaultsTest);
      for (final e in g.edges.values) {
        expect(e.dashed, isTrue);
      }
    });

    test('ports are parsed', () async {
      final g = await format.parse(portsTest);
      final e = g.edges.values.first;
      expect(e.source, 'A');
      expect(e.sourcePort, 'out');
    });

    test('subgraph endpoint fans out', () async {
      final g = await format.parse(subgraphEndpoint);
      // { A B } -> C creates two edges.
      final pairs = {
        for (final e in g.edges.values) '${e.source}->${e.target}',
      };
      expect(pairs, {'A->C', 'B->C'});
    });

    test('HTML labels are tolerated', () async {
      final g = await format.parse(htmlLabel);
      expect(g.nodes['A']!.label, contains('Hello'));
    });

    test('comments are ignored', () async {
      const src = '''
// line comment
digraph G {
  /* block
     comment */
  A -> B; // trailing
  # hash comment
}
''';
      final g = await format.parse(src);
      expect(g.nodes.keys.toSet(), {'A', 'B'});
    });

    test('rankdir variants', () async {
      expect(
        (await format.parse('digraph G { rankdir=TB; A->B; }'))
            .suggestedDirection,
        FlowLayoutDirection.topToBottom,
      );
      expect(
        (await format.parse('digraph G { rankdir=LR; A->B; }'))
            .suggestedDirection,
        FlowLayoutDirection.leftToRight,
      );
      expect(
        (await format.parse('digraph G { rankdir=RL; A->B; }'))
            .suggestedDirection,
        FlowLayoutDirection.rightToLeft,
      );
      expect(
        (await format.parse('digraph G { rankdir=BT; A->B; }'))
            .suggestedDirection,
        FlowLayoutDirection.bottomToTop,
      );
    });
  });

  group('GraphvizDotFormat.emit', () {
    test('emits digraph header', () async {
      final g = await format.parse(simpleDigraph);
      final out = await format.emit(g);
      expect(out.startsWith('digraph G {'), isTrue);
      expect(out.contains('rankdir=LR'), isTrue);
    });

    test('emits undirected header for undirected graphs', () async {
      final g = await format.parse(undirected);
      final out = await format.emit(g);
      expect(out.startsWith('graph G {'), isTrue);
      expect(out.contains(' -- '), isTrue);
    });

    test('round-trips simple digraph', () async {
      final g = await format.parse(simpleDigraph);
      final out = await format.emit(g);
      final g2 = await format.parse(out);

      expect(g2.nodes.keys.toSet(), g.nodes.keys.toSet());
      expect(g2.edges, hasLength(g.edges.length));
      expect(g2.nodes['A']!.label, 'Start');
      expect(g2.nodes['B']!.shape, 'ellipse');
    });

    test('round-trips clusters', () async {
      final g = await format.parse(clustered);
      final out = await format.emit(g);
      final g2 = await format.parse(out);

      expect(g2.groups.keys.toSet(), g.groups.keys.toSet());
      expect(g2.groups['cluster_exit']!.label, 'Exit');
      expect(g2.groups['cluster_exit']!.nodeIds.toSet(), {'E', 'EV'});
    });

    test('quotes node IDs that need it', () async {
      final g = await format.parse('digraph G { "hello world" -> B; }');
      final out = await format.emit(g);
      expect(out.contains('"hello world"'), isTrue);
    });
  });

  group('GraphvizDotFormat pipeline', () {
    test('import runs layout because DOT has no positions', () async {
      final registry = FlowFormatRegistry();
      registry.register(const GraphvizDotFormat());

      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAs(
        simpleDigraph,
        'dot',
        documentName: 'DOT Import',
      );

      final page = doc.firstPage!;
      expect(page.nodes, hasLength(2));
      // Every node got a non-empty rect.
      for (final n in page.nodes.values) {
        expect(n.rect.isEmpty, isFalse);
      }
    });

    test('detect routes to dot', () async {
      final registry = FlowFormatRegistry();
      registry.register(const GraphvizDotFormat());
      registry.register(const MermaidFlowchartFormat());
      registry.register(const DrawioXmlFormat());

      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAuto(simpleDigraph);
      expect(doc.firstPage!.nodes, hasLength(2));
    });

    test('document → DOT → document is stable', () async {
      final registry = FlowFormatRegistry();
      registry.register(const GraphvizDotFormat());
      final importer = FlowImportPipeline(registry: registry);
      final exporter = FlowExportPipeline(registry: registry);

      final doc1 = await importer.importAs(simpleDigraph, 'dot');
      final text = await exporter.exportAs(doc1, 'dot');
      final doc2 = await importer.importAs(text, 'dot');

      expect(doc2.firstPage!.nodes.length, doc1.firstPage!.nodes.length);
      expect(doc2.firstPage!.edges.length, doc1.firstPage!.edges.length);
    });
  });
}
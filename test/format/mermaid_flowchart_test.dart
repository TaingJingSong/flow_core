import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

const exitFlowExample = '''
flowchart TD
    E["Exit case"] --> EV["Exit case versions"]
    E --> F["Final pay"]
    E --> D["Documents"]
    F --> FV["Final pay versions"]
    EV --> FV
    FV --> I["Final pay items"]
    FV --> A["Approval tasks"]
    FV --> P["Payments"]
''';

void main() {
  const format = MermaidFlowchartFormat();

  group('MermaidFlowchartFormat.canParse', () {
    test('flowchart header', () {
      expect(format.canParse('flowchart TD\nA-->B'), isTrue);
    });
    test('graph header', () {
      expect(format.canParse('graph LR\nA-->B'), isTrue);
    });
    test('leading whitespace', () {
      expect(format.canParse('   \n  flowchart TD'), isTrue);
    });
    test('rejects sequence diagram', () {
      expect(format.canParse('sequenceDiagram\nA->>B: hi'), isFalse);
    });
  });

  group('MermaidFlowchartFormat.parse', () {
    test('user example: 8 nodes and 8 edges', () async {
      final g = await format.parse(exitFlowExample);
      expect(g.nodes.keys.toSet(), {'E', 'EV', 'F', 'D', 'FV', 'I', 'A', 'P'});
      expect(g.edges, hasLength(8));
    });

    test('user example: labels are preserved', () async {
      final g = await format.parse(exitFlowExample);
      expect(g.nodes['E']!.label, 'Exit case');
      expect(g.nodes['EV']!.label, 'Exit case versions');
      expect(g.nodes['F']!.label, 'Final pay');
      expect(g.nodes['D']!.label, 'Documents');
      expect(g.nodes['FV']!.label, 'Final pay versions');
    });

    test('direction is parsed', () async {
      expect(
        (await format.parse('flowchart LR\nA-->B')).suggestedDirection,
        FlowLayoutDirection.leftToRight,
      );
      expect(
        (await format.parse('flowchart TB\nA-->B')).suggestedDirection,
        FlowLayoutDirection.topToBottom,
      );
      expect(
        (await format.parse('flowchart BT\nA-->B')).suggestedDirection,
        FlowLayoutDirection.bottomToTop,
      );
      expect(
        (await format.parse('flowchart RL\nA-->B')).suggestedDirection,
        FlowLayoutDirection.rightToLeft,
      );
    });

    test('shapes are mapped', () async {
      final g = await format.parse('''
flowchart TD
  r[Rect]
  rd(Rounded)
  c((Circle))
  d{Diamond}
  h{{Hexagon}}
  s[[Subroutine]]
  cy[(Cylinder)]
  asy>Asymmetric]
''');
      expect(g.nodes['r']!.shape, 'rectangle');
      expect(g.nodes['rd']!.shape, 'rounded');
      expect(g.nodes['c']!.shape, 'circle');
      expect(g.nodes['d']!.shape, 'diamond');
      expect(g.nodes['h']!.shape, 'hexagon');
      expect(g.nodes['s']!.shape, 'subroutine');
      expect(g.nodes['cy']!.shape, 'cylinder');
      expect(g.nodes['asy']!.shape, 'asymmetric');
    });

    test('dashed and thick edges', () async {
      final g = await format.parse('''
flowchart TD
  A -.-> B
  C ==> D
  E --- F
''');
      final byLabel = {
        for (final e in g.edges.values) '${e.source}->${e.target}': e,
      };
      expect(byLabel['A->B']!.dashed, isTrue);
      expect(byLabel['A->B']!.targetArrow, FlowArrowHead.filledArrow);
      expect(byLabel['C->D']!.thick, isTrue);
      expect(byLabel['E->F']!.targetArrow, FlowArrowHead.none);
    });

    test('labeled edges', () async {
      final g = await format.parse('''
flowchart TD
  A -- yes --> B
  C -- no --> D
''');
      final bySource = {
        for (final e in g.edges.values) e.source: e,
      };
      expect(bySource['A']!.label, 'yes');
      expect(bySource['C']!.label, 'no');
    });

    test('chained edges', () async {
      final g = await format.parse('flowchart TD\nA --> B --> C --> D');
      expect(g.edges, hasLength(3));
      expect(g.nodes, hasLength(4));
    });

    test('comments are ignored', () async {
      final g = await format.parse('''
%% header comment
flowchart TD
  %% this is ignored
  A --> B
''');
      expect(g.nodes, hasLength(2));
      expect(g.edges, hasLength(1));
    });

    test('subgraph members are tagged', () async {
      final g = await format.parse('''
flowchart TD
  subgraph exit[Exit Stage]
    E --> EV
  end
  subgraph finance[Finance]
    F --> FV
  end
''');
      expect(g.nodes['E']!.groupId, 'exit');
      expect(g.nodes['F']!.groupId, 'finance');
      expect(g.groups['exit']!.label, 'Exit Stage');
      expect(g.groups['exit']!.nodeIds, containsAll(['E', 'EV']));
    });

    test('first non-bare declaration wins for labels', () async {
      final g = await format.parse('''
flowchart TD
  E["Real label"]
  E --> F
''');
      expect(g.nodes['E']!.label, 'Real label');
    });
  });

  group('MermaidFlowchartFormat.emit', () {
    test('round-trips user example', () async {
      final g = await format.parse(exitFlowExample);
      final s = await format.emit(g);
      final g2 = await format.parse(s);
      expect(g2.nodes.keys.toSet(), g.nodes.keys.toSet());
      expect(g2.edges, hasLength(g.edges.length));
      expect(g2.nodes['E']!.label, 'Exit case');
    });

    test('emits the header direction', () async {
      final g = await format.parse('flowchart LR\nA-->B');
      final s = await format.emit(g);
      expect(s.startsWith('flowchart LR'), isTrue);
    });
  });

  group('FlowImportPipeline', () {
    test('parses to a document with positions from layout', () async {
      final registry = FlowFormatRegistry();
      registry.register(const MermaidFlowchartFormat());

      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAs(
        exitFlowExample,
        'mermaid',
        documentName: 'Exit Flow',
      );

      expect(doc.name, 'Exit Flow');
      final page = doc.firstPage!;
      expect(page.nodes, hasLength(8));
      expect(page.edges, hasLength(8));

      // Every node has a non-empty rect after layout.
      for (final n in page.nodes.values) {
        expect(n.rect.isEmpty, isFalse,
            reason: 'node ${n.id} has empty rect after layout');
      }

      // Laid out top-to-bottom: E and EV are on different rows.
      final e = page.nodes[const FlowId('E')]!;
      final ev = page.nodes[const FlowId('EV')]!;
      expect(e.rect.top < ev.rect.top, isTrue);
    });

    test('detect works', () async {
      final registry = FlowFormatRegistry();
      registry.register(const MermaidFlowchartFormat());
      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAuto('flowchart TD\nA-->B');
      expect(doc.firstPage!.nodes, hasLength(2));
    });

    test('unknown format throws', () {
      final registry = FlowFormatRegistry();
      final pipeline = FlowImportPipeline(registry: registry);
      expect(
        () => pipeline.importAs('x', 'nope'),
        throwsArgumentError,
      );
    });
  });

  group('FlowExportPipeline', () {
    test('document → mermaid', () async {
      final registry = FlowFormatRegistry();
      registry.register(const MermaidFlowchartFormat());
      final importer = FlowImportPipeline(registry: registry);
      final exporter = FlowExportPipeline(registry: registry);

      final doc = await importer.importAs(exitFlowExample, 'mermaid');
      final text = await exporter.exportAs(doc, 'mermaid');
      expect(text.startsWith('flowchart TD'), isTrue);
      expect(text.contains('E'), isTrue);
      expect(text.contains('EV'), isTrue);
    });
  });
}
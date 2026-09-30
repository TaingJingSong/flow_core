import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

import '../fixtures/dot_fixtures.dart' as dot;
import '../fixtures/mermaid_fixtures.dart' as mermaid;

void main() {
  group('Cross-format conversion', () {
    const mermaidFormat = MermaidFlowchartFormat();
    const dotFormat = GraphvizDotFormat();
    const drawioFormat = DrawioXmlFormat();

    final registry = FlowFormatRegistry();
    registry.register(mermaidFormat);
    registry.register(dotFormat);
    registry.register(drawioFormat);

    final importer = FlowImportPipeline(registry: registry);
    final exporter = FlowExportPipeline(registry: registry);

    test('Mermaid → Document → DOT → Document', () async {
      final doc1 = await importer.importAs(
        mermaid.exitFlow.source,
        'mermaid',
        documentName: 'Exit',
      );
      expect(doc1.firstPage!.nodes, hasLength(8));

      final asDot = await exporter.exportAs(doc1, 'dot');
      expect(asDot, contains('digraph'));

      final doc2 = await importer.importAs(asDot, 'dot');
      expect(doc2.firstPage!.nodes.length, doc1.firstPage!.nodes.length);
      expect(doc2.firstPage!.edges.length, doc1.firstPage!.edges.length);
    });

    test('Mermaid → Document → draw.io → Document', () async {
      final doc1 = await importer.importAs(
        mermaid.exitFlow.source,
        'mermaid',
      );
      final asDrawio = await exporter.exportAs(doc1, 'drawio');
      expect(asDrawio, contains('<mxGraphModel>'));

      final doc2 = await importer.importAs(asDrawio, 'drawio');
      expect(doc2.firstPage!.nodes.length, doc1.firstPage!.nodes.length);
      // draw.io preserves layout.
      for (final n in doc2.firstPage!.nodes.values) {
        expect(n.rect.isEmpty, isFalse);
      }
    });

    test('DOT → Document → Mermaid → Document', () async {
      final doc1 = await importer.importAs(
        dot.simpleDigraph.source,
        'dot',
      );
      final asMermaid = await exporter.exportAs(doc1, 'mermaid');
      expect(asMermaid, startsWith('flowchart'));

      final doc2 = await importer.importAs(asMermaid, 'mermaid');
      expect(doc2.firstPage!.nodes.length, doc1.firstPage!.nodes.length);
    });

    test('DOT clustered → Document → DOT preserves groups', () async {
      final doc1 = await importer.importAs(dot.clustered.source, 'dot');
      expect(doc1.firstPage!.groups, hasLength(2));

      final back = await exporter.exportAs(doc1, 'dot');
      final doc2 = await importer.importAs(back, 'dot');
      expect(doc2.firstPage!.groups.length, doc1.firstPage!.groups.length);
    });

    test('draw.io → Document → Mermaid: positions dropped, topology kept', () async {
      const xml = '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="a" value="A" style="rounded=1;" vertex="1" parent="1">
      <mxGeometry x="100" y="100" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="b" value="B" style="rounded=1;" vertex="1" parent="1">
      <mxGeometry x="300" y="100" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="e1" style="endArrow=classic;" edge="1" parent="1" source="a" target="b">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''';
      final doc1 = await importer.importAs(xml, 'drawio');
      final mermaidText = await exporter.exportAs(doc1, 'mermaid');
      final doc2 = await importer.importAs(mermaidText, 'mermaid');

      expect(doc2.firstPage!.nodes.length, 2);
      expect(doc2.firstPage!.edges.length, 1);
    });

    test('detect routes correctly for all formats', () async {
      expect(
        registry.detect(mermaid.exitFlow.source)?.id,
        'mermaid',
      );
      expect(
        registry.detect(dot.simpleDigraph.source)?.id,
        'dot',
      );
      expect(
        registry.detect('<mxGraphModel></mxGraphModel>')?.id,
        'drawio',
      );
    });
  });
}
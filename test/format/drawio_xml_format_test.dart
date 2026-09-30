import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

const simpleMxfile = '''
<mxfile host="app.diagrams.net">
  <diagram id="abc" name="Page-1">
    <mxGraphModel dx="1422" dy="762" grid="1" gridSize="10">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="n1" value="Start"
                style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
                vertex="1" parent="1">
          <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="n2" value="End"
                style="ellipse;whiteSpace=wrap;html=1;fillColor=#d5e8d4;"
                vertex="1" parent="1">
          <mxGeometry x="400" y="300" width="100" height="100" as="geometry"/>
        </mxCell>
        <mxCell id="e1" value="next"
                style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=classic;"
                edge="1" parent="1" source="n1" target="n2">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="300" y="130"/>
              <mxPoint x="300" y="350"/>
            </Array>
          </mxGeometry>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
''';

const bareGraphModel = '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="a" value="A" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="0" y="0" width="80" height="40" as="geometry"/>
    </mxCell>
    <mxCell id="b" value="B" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="0" y="100" width="80" height="40" as="geometry"/>
    </mxCell>
    <mxCell id="e1" style="dashed=1;" edge="1" parent="1" source="a" target="b">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''';

const groupedGraphModel = '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="g1" value="Exit" style="group" vertex="1" parent="1">
      <mxGeometry x="50" y="50" width="400" height="200" as="geometry"/>
    </mxCell>
    <mxCell id="n1" value="Case" style="rounded=1;" vertex="1" parent="g1">
      <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="n2" value="Versions" style="rounded=1;" vertex="1" parent="g1">
      <mxGeometry x="300" y="100" width="120" height="60" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''';

void main() {
  const format = DrawioXmlFormat();

  group('DrawioXmlFormat.canParse', () {
    test('mxfile header', () {
      expect(format.canParse('<mxfile><diagram>...</diagram></mxfile>'), isTrue);
    });
    test('bare mxGraphModel', () {
      expect(format.canParse('<mxGraphModel>...</mxGraphModel>'), isTrue);
    });
    test('rejects mermaid', () {
      expect(format.canParse('flowchart TD\nA-->B'), isFalse);
    });
  });

  group('DrawioXmlFormat.parse', () {
    test('mxfile with two nodes and one edge', () async {
      final g = await format.parse(simpleMxfile);
      expect(g.nodes, hasLength(2));
      expect(g.edges, hasLength(1));

      final n1 = g.nodes['n1']!;
      expect(n1.label, 'Start');
      expect(n1.shape, 'rounded');
      expect(n1.rect, FlowRect.fromLTWH(100, 100, 120, 60));

      final n2 = g.nodes['n2']!;
      expect(n2.shape, 'circle');
      expect(n2.rect, FlowRect.fromLTWH(400, 300, 100, 100));
    });

    test('edge waypoints are read', () async {
      final g = await format.parse(simpleMxfile);
      final e = g.edges['e1']!;
      expect(e.label, 'next');
      expect(e.waypoints, hasLength(2));
      expect(e.waypoints.first, const FlowPoint(300, 130));
      expect(e.waypoints.last, const FlowPoint(300, 350));
      expect(e.targetArrow, FlowArrowHead.filledArrow);
    });

    test('style is preserved in data.drawio.style', () async {
      final g = await format.parse(simpleMxfile);
      final data = g.nodes['n1']!.data['drawio'] as Map?;
      expect(data, isNotNull);
      expect(data!['style'], contains('fillColor=#dae8fc'));
    });

    test('bare mxGraphModel at root', () async {
      final g = await format.parse(bareGraphModel);
      expect(g.nodes, hasLength(2));
      expect(g.edges, hasLength(1));
      expect(g.edges['e1']!.dashed, isTrue);
      expect(g.edges['e1']!.targetArrow, FlowArrowHead.filledArrow);
    });

    test('group is parsed with rect and children', () async {
      final g = await format.parse(groupedGraphModel);
      expect(g.groups, hasLength(1));
      final grp = g.groups['g1']!;
      expect(grp.label, 'Exit');
      expect(grp.rect, FlowRect.fromLTWH(50, 50, 400, 200));
      expect(grp.nodeIds.toSet(), {'n1', 'n2'});
      expect(g.nodes['n1']!.groupId, 'g1');
      expect(g.nodes['n2']!.groupId, 'g1');
    });

    test('rejects compressed diagram with a clear message', () {
      const compressed = '''
<mxfile>
  <diagram id="x" name="Page-1">eJyrVkrLz1eyUjA0MFDSUUrOz0lNzQOKGZqba4GFjMwtlGoB7I4Lgw==</diagram>
</mxfile>
''';
      expect(
        () => format.parse(compressed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Compressed'),
          ),
        ),
      );
    });
  });

  group('DrawioXmlFormat.emit', () {
    test('round-trips the simple mxfile', () async {
      final g = await format.parse(simpleMxfile);
      final out = await format.emit(g);
      final g2 = await format.parse(out);

      expect(g2.nodes.keys.toSet(), g.nodes.keys.toSet());
      expect(g2.edges.keys.toSet(), g.edges.keys.toSet());
      expect(g2.nodes['n1']!.rect, g.nodes['n1']!.rect);
      expect(g2.nodes['n1']!.label, 'Start');
      expect(g2.edges['e1']!.waypoints, g.edges['e1']!.waypoints);
    });

    test('emits a valid mxGraphModel', () async {
      final g = await format.parse(simpleMxfile);
      final out = await format.emit(g);
      expect(out.startsWith('<mxGraphModel>'), isTrue);
      expect(out.contains('id="0"'), isTrue);
      expect(out.contains('id="1"'), isTrue);
      expect(out.contains('vertex="1"'), isTrue);
      expect(out.contains('edge="1"'), isTrue);
    });

    test('preserved style is emitted verbatim', () async {
      final g = await format.parse(simpleMxfile);
      final out = await format.emit(g);
      expect(out.contains('fillColor=#dae8fc'), isTrue);
    });

    test('groups round-trip with their rect', () async {
      final g = await format.parse(groupedGraphModel);
      final out = await format.emit(g);
      final g2 = await format.parse(out);
      expect(g2.groups['g1']!.rect, FlowRect.fromLTWH(50, 50, 400, 200));
      expect(g2.groups['g1']!.nodeIds.toSet(), {'n1', 'n2'});
    });
  });

  group('DrawioXmlFormat pipeline', () {
    test('import produces a positioned document', () async {
      final registry = FlowFormatRegistry();
      registry.register(const DrawioXmlFormat());
      registry.register(const MermaidFlowchartFormat());

      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAs(
        simpleMxfile,
        'drawio',
        documentName: 'Drawio Import',
      );

      final page = doc.firstPage!;
      expect(page.nodes, hasLength(2));
      expect(page.edges, hasLength(1));
      expect(page.nodes[const FlowId('n1')]!.rect,
          FlowRect.fromLTWH(100, 100, 120, 60));
    });

    test('detect routes mxfile to drawio', () async {
      final registry = FlowFormatRegistry();
      registry.register(const DrawioXmlFormat());
      registry.register(const MermaidFlowchartFormat());

      final pipeline = FlowImportPipeline(registry: registry);
      final doc = await pipeline.importAuto(simpleMxfile);
      expect(doc.firstPage!.nodes, hasLength(2));
    });

    test('export→import is stable', () async {
      final registry = FlowFormatRegistry();
      registry.register(const DrawioXmlFormat());
      final importer = FlowImportPipeline(registry: registry);
      final exporter = FlowExportPipeline(registry: registry);

      final doc = await importer.importAs(simpleMxfile, 'drawio');
      final xml = await exporter.exportAs(doc, 'drawio');
      final doc2 = await importer.importAs(xml, 'drawio');

      expect(doc2.firstPage!.nodes.length, doc.firstPage!.nodes.length);
      expect(doc2.firstPage!.edges.length, doc.firstPage!.edges.length);
    });
  });
}
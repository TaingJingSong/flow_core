import 'dart:convert';

import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

FlowDocument buildSampleDocument() {
  const layer = FlowLayer(id: FlowId('default'), name: 'Default');

  final start = FlowNode(
    id: FlowId('n_start'),
    type: 'circle',
    rect: FlowRect.fromLTWH(0, 0, 60, 60),
    label: FlowLabel(text: 'Start'),
    tags: {'entry'},
    meta: {'stereotype': 'start'},
  );

  final exit = FlowNode(
    id: FlowId('n_exit'),
    type: 'rectangle',
    rect: FlowRect.fromLTWH(200, 0, 120, 60),
    label: FlowLabel(text: 'Exit case'),
    ports: [
      FlowPort(name: 'in', side: FlowPortSide.left, kind: FlowPortKind.input),
      FlowPort(name: 'out', side: FlowPortSide.right, kind: FlowPortKind.output),
    ],
    data: {
      'payload': {'size': 3, 'tags': ['a', 'b']},
    },
  );

  final versions = FlowNode(
    id: FlowId('n_versions'),
    type: 'rectangle',
    rect: FlowRect.fromLTWH(200, 100, 160, 60),
    label: FlowLabel(text: 'Exit case versions'),
  );

  const edge = FlowEdge(
    id: FlowId('e1'),
    sourceNodeId: FlowId('n_exit'),
    targetNodeId: FlowId('n_versions'),
    sourcePortName: 'out',
    kind: FlowEdgeKind.flow,
    routing: FlowEdgeRouting.orthogonal,
    waypoints: [FlowPoint(380, 30), FlowPoint(380, 130)],
    targetArrow: FlowArrowHead.filledArrow,
    label: FlowLabel(text: 'yes'),
    meta: {'weight': '1'},
  );

  final group = FlowGroup(
    id: FlowId('g1'),
    rect: FlowRect.fromLTWH(180, -20, 220, 220),
    label: FlowLabel(text: 'Exit'),
    childNodeIds: [FlowId('n_exit'), FlowId('n_versions')],
    style: FlowStyle(cornerRadius: 8, strokeDashPattern: [4, 2]),
  );

  final page = FlowPage(
    id: const FlowId('page_1'),
    name: 'Main',
    layers: {layer.id: layer},
    nodes: {
      start.id: start,
      exit.id: exit,
      versions.id: versions,
    },
    edges: {edge.id: edge},
    groups: {group.id: group},
    meta: {'zoom': '1.0'},
  );

  return FlowDocument(
    id: const FlowId('doc_1'),
    name: 'Exit Flow',
    pages: [page],
    metadata: FlowMetadata(
      title: 'Exit Flow',
      author: 'Pocket',
      createdAt: DateTime.utc(2025, 1, 1),
      tags: const {'flow'},
      custom: const {'source': 'mermaid'},
    ),
  );
}

void main() {
  const codec = FlowJsonCodec();

  group('FlowJsonCodec', () {
    test('round trips a full document via map', () {
      final original = buildSampleDocument();
      final json = codec.encode(original);
      final restored = codec.decode(json);
      expect(restored, original);
    });

    test('round trips a full document via string', () {
      final original = buildSampleDocument();
      final s = codec.encodeToString(original);
      final restored = codec.decodeFromString(s);
      expect(restored, original);
    });

    test('pretty output is valid JSON and round trips', () {
      final original = buildSampleDocument();
      final pretty = codec.encodeToString(original, pretty: true);
      expect(pretty.contains('\n'), isTrue);
      final restored = codec.decodeFromString(pretty);
      expect(restored, original);
    });

    test('null optional fields are omitted', () {
      const node = FlowNode(
        id: FlowId('n'),
        type: 'rectangle',
        rect: FlowRect.zero,
      );
      final json = codec.encode(FlowDocument(
        id: const FlowId('d'),
        pages: [
          FlowPage(
            id: const FlowId('p'),
            name: 'P',
            nodes: {node.id: node},
          ),
        ],
      ));
      final encodedNode = (json['pages']! as List).first['nodes'][0] as Map;
      expect(encodedNode.containsKey('label'), isFalse);
      expect(encodedNode.containsKey('parentGroupId'), isFalse);
      expect(encodedNode.containsKey('layerId'), isFalse);
      expect(encodedNode.containsKey('rotation'), isFalse);
      expect(encodedNode.containsKey('zIndex'), isFalse);
    });

    test('colors use #AARRGGBB and short form decodes with full alpha', () {
      final decoded = FlowJsonCodec();
      const style = FlowStyle(
        fillColor: FlowColor.fromARGB(0x80, 0x12, 0x34, 0x56),
        strokeColor: FlowColor(0xFFAABBCC),
      );
      final node = FlowNode(
        id: const FlowId('n'),
        type: 'rectangle',
        rect: FlowRect.zero,
        style: style,
      );
      final doc = FlowDocument(
        id: const FlowId('d'),
        pages: [
          FlowPage(
            id: const FlowId('p'),
            name: 'P',
            nodes: {node.id: node},
          ),
        ],
      );
      final json = decoded.encode(doc);
      final nodeJson = ((json['pages']! as List).first as Map)['nodes'][0]
          as Map;
      expect((nodeJson['style'] as Map)['fillColor'], '#80123456');
      expect((nodeJson['style'] as Map)['strokeColor'], '#FFAABBCC');

      // Short form on decode
      final tampered = jsonDecode(jsonEncode(json)) as Map;
      final tNode =
          ((tampered['pages']! as List).first as Map)['nodes'][0] as Map;
      (tNode['style'] as Map)['fillColor'] = '#112233';
      final restored = decoded.decode(tampered.cast<String, Object?>());
      final restoredNode = restored.pages.first.nodes.values.first;
      expect(restoredNode.style.fillColor, const FlowColor(0xFF112233));
    });

    test('unknown enum value falls back to default', () {
      final json = <String, Object?>{
        'schemaVersion': FlowDocument.currentSchemaVersion,
        'id': 'd',
        'name': 'D',
        'metadata': <String, Object?>{},
        'pages': [
          {
            'id': 'p',
            'name': 'P',
            'layers': [
              {'id': 'default', 'name': 'Default'},
            ],
            'edges': [
              {
                'id': 'e1',
                'source': 'a',
                'target': 'b',
                'kind': 'not-a-real-kind',
                'routing': 'not-a-real-routing',
                'sourceArrow': 'bogus',
                'targetArrow': 'bogus',
                'style': <String, Object?>{},
              },
            ],
          },
        ],
      };
      final doc = codec.decode(json);
      final edge = doc.pages.first.edges.values.first;
      expect(edge.kind, FlowEdgeKind.flow);
      expect(edge.routing, FlowEdgeRouting.straight);
      expect(edge.sourceArrow, FlowArrowHead.none);
      expect(edge.targetArrow, FlowArrowHead.filledArrow);
    });

    test('missing schemaVersion throws', () {
      expect(
        () => codec.decode({'id': 'd'}),
        throwsA(isA<FlowMigrationException>()),
      );
    });

    test('newer schemaVersion throws', () {
      expect(
        () => codec.decode({
          'schemaVersion': FlowDocument.currentSchemaVersion + 1,
          'id': 'd',
        }),
        throwsA(isA<FlowMigrationException>()),
      );
    });

    test('rejects non-object root from string', () {
      expect(
        () => codec.decodeFromString('[]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('empty document round trips', () {
      final doc = FlowDocument.empty(id: const FlowId('empty'));
      final s = codec.encodeToString(doc);
      expect(codec.decodeFromString(s), doc);
    });
  });
}
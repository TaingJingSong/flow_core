import 'package:collection/collection.dart';
import 'package:flow_core/flow_core.dart';
import 'package:xml/xml.dart';

/// draw.io / diagrams.net XML parser and emitter.
///
/// Handles uncompressed `<mxGraphModel>` files, whether the root is
/// `<mxGraphModel>` directly or wrapped in `<mxfile><diagram>`.
///
/// Compressed diagrams (base64 + deflate) are not supported and cause
/// [parse] to throw a [FormatException].
class DrawioXmlFormat extends FlowFormat {
  const DrawioXmlFormat();

  @override
  String get id => 'drawio';

  @override
  String get name => 'draw.io XML';

  @override
  List<String> get extensions => const ['.drawio', '.xml'];

  @override
  bool canParse(String content) {
    final head = content.length > 400 ? content.substring(0, 400) : content;
    return head.contains('<mxGraphModel') || head.contains('<mxfile');
  }

  @override
  Future<FlowGraph> parse(String content, {FlowFormatOptions? options}) async {
    final doc = XmlDocument.parse(content);
    final model = _findFirst(doc.rootElement, 'mxGraphModel');
    if (model == null) {
      throw const FormatException(
        'No <mxGraphModel> found. '
        'Compressed diagrams are not yet supported; '
        'save from draw.io with "Compressed" unchecked.',
      );
    }
    return _DrawioParser(model).parse();
  }

  @override
  Future<String> emit(FlowGraph graph, {FlowFormatOptions? options}) async {
    return _DrawioEmitter(graph).emit();
  }

  static XmlElement? _findFirst(XmlElement root, String localName) {
    if (root.name.local == localName) return root;
    for (final child in root.childElements) {
      final found = _findFirst(child, localName);
      if (found != null) return found;
    }
    return null;
  }
}

// -----------------------------------------------------------------------------
// Parser
// -----------------------------------------------------------------------------

class _DrawioParser {
  _DrawioParser(this.model);

  final XmlElement model;

  final _nodes = <String, FlowGraphNode>{};
  final _edges = <String, FlowGraphEdge>{};
  final _groups = <String, FlowGraphGroup>{};
  int edgeCounter = 0;

  FlowGraph parse() {
    final root = _findChild(model, 'root');
    if (root == null) {
      throw const FormatException('Missing <root> in <mxGraphModel>.');
    }

    // Collect cells in document order.
    final cells = <String, XmlElement>{};
    final order = <String>[];
    for (final c in root.childElements) {
      if (c.name.local != 'mxCell') continue;
      final id = c.getAttribute('id');
      if (id == null) continue;
      cells[id] = c;
      order.add(id);
    }

    // Build parent → children map to detect groups.
    final childrenOf = <String, List<String>>{};
    for (final id in order) {
      final parent = cells[id]!.getAttribute('parent');
      if (parent == null) continue;
      childrenOf.putIfAbsent(parent, () => []).add(id);
    }

    final groupIds = <String>{};
    for (final id in order) {
      final c = cells[id]!;
      if (c.getAttribute('vertex') != '1') continue;
      final style = c.getAttribute('style') ?? '';
      final isGroupStyle = style.split(';').any((s) => s == 'group');
      final hasChildren =
          (childrenOf[id] ?? const []).where((child) {
        final cc = cells[child];
        return cc != null &&
            (cc.getAttribute('vertex') == '1' || cc.getAttribute('edge') == '1');
      }).isNotEmpty;
      if (isGroupStyle || hasChildren) {
        groupIds.add(id);
      }
    }

    // Second pass: emit nodes, groups, edges.
    for (final id in order) {
      final cell = cells[id]!;
      final vertex = cell.getAttribute('vertex') == '1';
      final edge = cell.getAttribute('edge') == '1';

      if (vertex && groupIds.contains(id)) {
        _parseGroup(id, cell);
      } else if (vertex) {
        _parseNode(id, cell);
      } else if (edge) {
        _parseEdge(id, cell);
      }
    }

    // Populate group membership from parent links.
    for (final id in order) {
      final cell = cells[id]!;
      final parent = cell.getAttribute('parent');
      if (parent == null) continue;
      final group = _groups[parent];
      if (group == null) continue;
      if (_nodes.containsKey(id)) {
        _groups[parent] = group.copyWith(
          nodeIds: [...group.nodeIds, id],
        );
        final node = _nodes[id]!;
        _nodes[id] = node.copyWith(groupId: parent);
      } else if (_groups.containsKey(id)) {
        _groups[parent] = group.copyWith(
          childGroupIds: [...group.childGroupIds, id],
        );
      }
    }

    return FlowGraph(
      nodes: _nodes,
      edges: _edges,
      groups: _groups,
      suggestedDirection: FlowLayoutDirection.topToBottom,
      suggestedLayout: 'layered',
      meta: const {'source': 'drawio'},
    );
  }

  void _parseNode(String id, XmlElement cell) {
    final value = cell.getAttribute('value') ?? '';
    final style = cell.getAttribute('style');
    final geo = _findChild(cell, 'mxGeometry');
    final rect = _readRect(geo);
    final shape = DrawioStyle.parseShape(style);

    // Stash the raw style so round-trips are lossless.
    final data = <String, Object?>{};
    if (style != null && style.isNotEmpty) {
      data['drawio'] = <String, Object?>{'style': style};
    }

    _nodes[id] = FlowGraphNode(
      id: id,
      label: value,
      shape: shape,
      rect: rect,
      data: data,
    );
  }

  void _parseGroup(String id, XmlElement cell) {
    final value = cell.getAttribute('value') ?? '';
    final geo = _findChild(cell, 'mxGeometry');
    final rect = _readRect(geo);

    _groups[id] = FlowGraphGroup(
      id: id,
      label: value,
      rect: rect,
    );
  }

  void _parseEdge(String id, XmlElement cell) {
    final source = cell.getAttribute('source');
    final target = cell.getAttribute('target');
    if (source == null || target == null) return;

    final value = cell.getAttribute('value') ?? '';
    final style = cell.getAttribute('style');
    final parsed = DrawioStyle.parseEdgeStyle(style);
    final waypoints = _readWaypoints(cell);

    final data = <String, Object?>{};
    if (style != null && style.isNotEmpty) {
      data['drawio'] = <String, Object?>{'style': style};
    }

    _edges[id] = FlowGraphEdge(
      id: id,
      source: source,
      target: target,
      label: value,
      kind: FlowEdgeKind.flow,
      sourceArrow: parsed.startArrow,
      targetArrow: parsed.endArrow,
      waypoints: waypoints,
      dashed: parsed.dashed,
      thick: parsed.thick,
      data: data,
    );
    edgeCounter++;
  }

  FlowRect? _readRect(XmlElement? geo) {
    if (geo == null) return null;
    final x = double.tryParse(geo.getAttribute('x') ?? '') ?? 0;
    final y = double.tryParse(geo.getAttribute('y') ?? '') ?? 0;
    final w = double.tryParse(geo.getAttribute('width') ?? '') ?? 0;
    final h = double.tryParse(geo.getAttribute('height') ?? '') ?? 0;
    if (w <= 0 || h <= 0) return null;
    return FlowRect.fromLTWH(x, y, w, h);
  }

  List<FlowPoint> _readWaypoints(XmlElement cell) {
    final geo = _findChild(cell, 'mxGeometry');
    if (geo == null) return const <FlowPoint>[];
    final array = geo.childElements.firstWhereOrNull(
      (e) => e.name.local == 'Array' && e.getAttribute('as') == 'points',
    );
    if (array == null) return const <FlowPoint>[];
    final out = <FlowPoint>[];
    for (final pt in array.childElements) {
      if (pt.name.local != 'mxPoint') continue;
      final x = double.tryParse(pt.getAttribute('x') ?? '') ?? 0;
      final y = double.tryParse(pt.getAttribute('y') ?? '') ?? 0;
      out.add(FlowPoint(x, y));
    }
    return out;
  }

  XmlElement? _findChild(XmlElement parent, String localName) {
    for (final c in parent.childElements) {
      if (c.name.local == localName) return c;
    }
    return null;
  }
}

// -----------------------------------------------------------------------------
// Emitter
// -----------------------------------------------------------------------------

class _DrawioEmitter {
  _DrawioEmitter(this.graph);

  final FlowGraph graph;

  String emit() {
    final b = StringBuffer();
    b.writeln('<mxGraphModel>');
    b.writeln('  <root>');
    b.writeln('    <mxCell id="0"/>');
    b.writeln('    <mxCell id="1" parent="0"/>');

    // Groups first so children can reference them by parent.
    for (final g in graph.groups.values) {
      _emitGroup(b, g);
    }
    for (final n in graph.nodes.values) {
      _emitNode(b, n);
    }
    for (final e in graph.edges.values) {
      _emitEdge(b, e);
    }

    b.writeln('  </root>');
    b.writeln('</mxGraphModel>');
    return b.toString();
  }

  void _emitGroup(StringBuffer b, FlowGraphGroup g) {
    final rect = g.rect ?? _computedGroupRect(g);
    final x = rect?.left ?? 0;
    final y = rect?.top ?? 0;
    final w = rect?.width ?? 0;
    final h = rect?.height ?? 0;

    b.writeln(
      '    <mxCell id="${_attr(g.id)}" '
      'value="${_attr(g.label)}" '
      'style="group" '
      'vertex="1" '
      'parent="${_parentFor(g.parentId)}">',
    );
    b.writeln(
      '      <mxGeometry x="$x" y="$y" width="$w" height="$h" as="geometry"/>',
    );
    b.writeln('    </mxCell>');
  }

  void _emitNode(StringBuffer b, FlowGraphNode n) {
    final rect = n.rect ?? FlowRect.fromLTWH(0, 0, 120, 60);
    final preserve = (n.data['drawio'] as Map?)?['style'] as String?;
    final style = DrawioStyle.emitNodeStyle(
      FlowStyle.defaults,
      shape: n.shape,
      preserve: preserve,
    );

    b.writeln(
      '    <mxCell id="${_attr(n.id)}" '
      'value="${_attr(n.label)}" '
      'style="${_attr(style)}" '
      'vertex="1" '
      'parent="${_parentFor(n.groupId)}">',
    );
    b.writeln(
      '      <mxGeometry x="${rect.left}" y="${rect.top}" '
      'width="${rect.width}" height="${rect.height}" as="geometry"/>',
    );
    b.writeln('    </mxCell>');
  }

  void _emitEdge(StringBuffer b, FlowGraphEdge e) {
    final preserve = (e.data['drawio'] as Map?)?['style'] as String?;
    final style = DrawioStyle.emitEdgeStyle(
      dashed: e.dashed,
      thick: e.thick,
      startArrow: e.sourceArrow,
      endArrow: e.targetArrow,
      preserve: preserve,
    );

    b.writeln(
      '    <mxCell id="${_attr(e.id)}" '
      'value="${_attr(e.label)}" '
      'style="${_attr(style)}" '
      'edge="1" '
      'parent="1" '
      'source="${_attr(e.source)}" '
      'target="${_attr(e.target)}">',
    );

    if (e.waypoints.isEmpty) {
      b.writeln('      <mxGeometry relative="1" as="geometry"/>');
    } else {
      b.writeln('      <mxGeometry relative="1" as="geometry">');
      b.writeln('        <Array as="points">');
      for (final p in e.waypoints) {
        b.writeln('          <mxPoint x="${p.x}" y="${p.y}"/>');
      }
      b.writeln('        </Array>');
      b.writeln('      </mxGeometry>');
    }
    b.writeln('    </mxCell>');
  }

  FlowRect? _computedGroupRect(FlowGraphGroup g) {
    final rects = <FlowRect>[];
    for (final id in g.nodeIds) {
      final r = graph.nodes[id]?.rect;
      if (r != null) rects.add(r);
    }
    if (rects.isEmpty) return null;
    var acc = rects.first;
    for (var i = 1; i < rects.length; i++) {
      acc = acc.union(rects[i]);
    }
    return acc.inflate(20);
  }

  String _parentFor(String? id) => id ?? '1';

  static String _attr(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
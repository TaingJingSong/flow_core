import '../../layout/flow_layout_direction.dart';
import '../../model/flow_arrow_head.dart';
import '../../model/flow_edge_kind.dart';
import '../flow_format.dart';
import '../flow_format_options.dart';
import '../flow_graph.dart';

/// Mermaid `flowchart` / `graph` parser and emitter (Tier 1).
///
/// Supports:
/// - Headers `flowchart <dir>` and `graph <dir>` with TD/TB/BT/LR/RL.
/// - Node shapes: `[]`, `()`, `(())`, `{}`, `{{}}`, `[[]]`, `[()]`, `>]`.
/// - Edges: `-->`, `---`, `-.->`, `-.-`, `==>`, `===`.
/// - Labeled edges: `--text-->`, `--text---`, `-.text.->`, `==text==>`.
/// - Subgraphs: `subgraph <id>[<label>] ... end`.
/// - Comments: `%% ...`.
///
/// Tier 2+ (unimplemented): `style`, `classDef`, `class`, `linkStyle`,
/// `click`, and non-flowchart diagram types.
class MermaidFlowchartFormat extends FlowFormat {
  const MermaidFlowchartFormat();

  @override
  String get id => 'mermaid';

  @override
  String get name => 'Mermaid Flowchart';

  @override
  List<String> get extensions => const ['.mmd', '.mermaid'];

  @override
  bool canParse(String content) {
    final trimmed = content.trimLeft();
    return RegExp(r'^(flowchart|graph)(\s|$)').hasMatch(trimmed);
  }

  @override
  Future<FlowGraph> parse(String content, {FlowFormatOptions? options}) async {
    return _MermaidFlowchartParser(content).parse();
  }

  @override
  Future<String> emit(FlowGraph graph, {FlowFormatOptions? options}) async {
    return _emitMermaid(graph);
  }
}

// -----------------------------------------------------------------------------
// Parser
// -----------------------------------------------------------------------------

class _MermaidFlowchartParser {
  _MermaidFlowchartParser(this.source);

  final String source;

  final _nodes = <String, FlowGraphNode>{};
  final _edges = <String, FlowGraphEdge>{};
  final _groups = <String, FlowGraphGroup>{};
  final _groupStack = <_GroupBuilder>[];
  int _edgeCounter = 0;
  FlowLayoutDirection _direction = FlowLayoutDirection.topToBottom;

  FlowGraph parse() {
    final lines = _splitLines(source);

    var i = 0;
    while (i < lines.length && lines[i].trim().isEmpty) {
      i++;
    }
    if (i >= lines.length) {
      throw const FormatException('Missing Mermaid flowchart header.');
    }
    _direction = _parseDirection(lines[i].trim());
    i++;

    for (; i < lines.length; i++) {
      _parseLine(lines[i]);
    }

    // Close any dangling subgraphs (defensive).
    while (_groupStack.isNotEmpty) {
      _closeGroup();
    }

    return FlowGraph(
      nodes: _nodes,
      edges: _edges,
      groups: _groups,
      suggestedDirection: _direction,
      suggestedLayout: 'layered',
      meta: const {'source': 'mermaid'},
    );
  }

  List<String> _splitLines(String source) {
    final out = <String>[];
    for (final raw in source.split('\n')) {
      final idx = _indexOfComment(raw);
      out.add(idx < 0 ? raw : raw.substring(0, idx));
    }
    return out;
  }

  int _indexOfComment(String line) {
    var inQuote = false;
    for (var i = 0; i < line.length - 1; i++) {
      final c = line[i];
      if (c == '"') inQuote = !inQuote;
      if (!inQuote && c == '%' && line[i + 1] == '%') return i;
    }
    return -1;
  }

  FlowLayoutDirection _parseDirection(String header) {
    final parts = header.split(RegExp(r'\s+'));
    if (parts.length < 2) return FlowLayoutDirection.topToBottom;
    switch (parts[1].toUpperCase()) {
      case 'TD':
      case 'TB':
        return FlowLayoutDirection.topToBottom;
      case 'BT':
        return FlowLayoutDirection.bottomToTop;
      case 'LR':
        return FlowLayoutDirection.leftToRight;
      case 'RL':
        return FlowLayoutDirection.rightToLeft;
    }
    return FlowLayoutDirection.topToBottom;
  }

  void _parseLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return;

    if (line == 'end') {
      _closeGroup();
      return;
    }
    if (line.startsWith('subgraph ')) {
      _openGroup(line.substring(9).trim());
      return;
    }
    if (_startsWithDirective(line)) return;

    _parseChain(line);
  }

  bool _startsWithDirective(String line) {
    for (final d in const [
      'style ',
      'classDef ',
      'class ',
      'linkStyle ',
      'click ',
    ]) {
      if (line.startsWith(d)) return true;
    }
    return false;
  }

  void _openGroup(String header) {
    header = header.trim();
    String id;
    String label;

    if (header.startsWith('"')) {
      final end = header.lastIndexOf('"');
      if (end > 0) {
        label = header.substring(1, end);
        id = label.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
      } else {
        label = header;
        id = header;
      }
    } else {
      final bracket = header.indexOf('[');
      if (bracket >= 0) {
        id = header.substring(0, bracket).trim();
        final rest = header.substring(bracket);
        label = _readBracketBody(rest);
      } else {
        final parts = header.split(RegExp(r'\s+'));
        id = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
        label = header;
      }
    }
    if (id.isEmpty) id = label;

    _groupStack.add(_GroupBuilder(
      id: id,
      label: label,
      parentId: _groupStack.isEmpty ? null : _groupStack.last.id,
    ));
  }

  void _closeGroup() {
    if (_groupStack.isEmpty) return;
    final b = _groupStack.removeLast();
    final existing = _groups[b.id];
    if (existing != null) {
      _groups[b.id] = existing.copyWith(
        nodeIds: [...existing.nodeIds, ...b.nodeIds],
        childGroupIds: [...existing.childGroupIds, ...b.childGroupIds],
      );
    } else {
      _groups[b.id] = FlowGraphGroup(
        id: b.id,
        label: b.label,
        parentId: b.parentId,
        nodeIds: List.unmodifiable(b.nodeIds),
        childGroupIds: List.unmodifiable(b.childGroupIds),
      );
    }
    if (_groupStack.isNotEmpty) {
      _groupStack.last.childGroupIds.add(b.id);
    }
  }

  void _parseChain(String line) {
    final s = _Scanner(line);
    s.skipWhitespace();

    var current = _readNode(s);
    if (current == null) return;
    _registerNode(current);

    while (true) {
      s.skipWhitespace();
      if (s.atEnd) break;

      final edge = _readEdge(s);
      if (edge == null) break;

      s.skipWhitespace();
      final next = _readNode(s);
      if (next == null) break;
      _registerNode(next);

      if (current != null) _addEdge(current, next, edge);
      current = next;
    }
  }

  void _registerNode(_NodeRef ref) {
    final existing = _nodes[ref.id];
    if (existing == null) {
      final groupId = _groupStack.isEmpty ? null : _groupStack.last.id;
      _nodes[ref.id] = FlowGraphNode(
        id: ref.id,
        label: ref.isBare ? '' : ref.label,
        shape: ref.isBare ? 'rectangle' : ref.shape,
        groupId: groupId,
      );
      if (_groupStack.isNotEmpty) {
        _groupStack.last.nodeIds.add(ref.id);
      }
    } else if (!ref.isBare) {
      _nodes[ref.id] = existing.copyWith(label: ref.label, shape: ref.shape);
    }
  }

  void _addEdge(_NodeRef from, _NodeRef to, _ParsedEdge edge) {
    final id = 'e${++_edgeCounter}';
    _edges[id] = FlowGraphEdge(
      id: id,
      source: from.id,
      target: to.id,
      label: edge.label,
      kind: FlowEdgeKind.flow,
      sourceArrow: FlowArrowHead.none,
      targetArrow:
          edge.hasArrow ? FlowArrowHead.filledArrow : FlowArrowHead.none,
      dashed: edge.dashed,
      thick: edge.thick,
    );
  }

  _NodeRef? _readNode(_Scanner s) {
    s.skipWhitespace();
    final start = s.pos;
    final id = s.readIdentifier();
    if (id.isEmpty) {
      s.pos = start;
      return null;
    }
    s.skipWhitespace();
    final shape = _tryReadShape(s);
    if (shape == null) {
      return _NodeRef(id: id, label: '', shape: 'rectangle', isBare: true);
    }
    return _NodeRef(
      id: id,
      label: shape.label.isEmpty ? id : shape.label,
      shape: shape.shape,
      isBare: false,
    );
  }

  _ShapeAndLabel? _tryReadShape(_Scanner s) {
    final start = s.pos;
    if (s.match('[[')) {
      final body = s.readUntil(']]');
      if (body != null) return _ShapeAndLabel('subroutine', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('[(')) {
      final body = s.readUntil(')]');
      if (body != null) return _ShapeAndLabel('cylinder', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('((')) {
      final body = s.readUntil('))');
      if (body != null) return _ShapeAndLabel('circle', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('{{')) {
      final body = s.readUntil('}}');
      if (body != null) return _ShapeAndLabel('hexagon', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('>')) {
      final body = s.readUntil(']');
      if (body != null) return _ShapeAndLabel('asymmetric', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('[')) {
      final body = s.readUntil(']');
      if (body != null) return _ShapeAndLabel('rectangle', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('(')) {
      final body = s.readUntil(')');
      if (body != null) return _ShapeAndLabel('rounded', _unquote(body));
      s.pos = start;
      return null;
    }
    if (s.match('{')) {
      final body = s.readUntil('}');
      if (body != null) return _ShapeAndLabel('diamond', _unquote(body));
      s.pos = start;
      return null;
    }
    return null;
  }

  _ParsedEdge? _readEdge(_Scanner s) {
    s.skipWhitespace();
    final start = s.pos;

    // Simple operators, longest first.
    if (s.match('-.->'))
      return const _ParsedEdge(label: '', hasArrow: true, dashed: true);
    if (s.match('-.-'))
      return const _ParsedEdge(label: '', hasArrow: false, dashed: true);
    if (s.match('==>'))
      return const _ParsedEdge(label: '', hasArrow: true, thick: true);
    if (s.match('==='))
      return const _ParsedEdge(label: '', hasArrow: false, thick: true);
    if (s.match('-->')) return const _ParsedEdge(label: '', hasArrow: true);
    if (s.match('---')) return const _ParsedEdge(label: '', hasArrow: false);

    s.pos = start;

    // Labeled solid: -- <label> --> or -- <label> ---
    if (s.match('--')) {
      final endArrow = s.source.indexOf('-->', s.pos);
      final endPlain = s.source.indexOf('---', s.pos);
      if (endArrow >= 0 && (endPlain < 0 || endArrow <= endPlain)) {
        final label = s.source.substring(s.pos, endArrow).trim();
        s.pos = endArrow + 3;
        return _ParsedEdge(label: label, hasArrow: true);
      }
      if (endPlain >= 0) {
        final label = s.source.substring(s.pos, endPlain).trim();
        s.pos = endPlain + 3;
        return _ParsedEdge(label: label, hasArrow: false);
      }
      s.pos = start;
      return null;
    }

    // Labeled dashed: -. <label> .-> or -. <label> .-
    if (s.match('-.')) {
      final endArrow = s.source.indexOf('.->', s.pos);
      final endPlain = s.source.indexOf('.-', s.pos);
      if (endArrow >= 0 && (endPlain < 0 || endArrow <= endPlain)) {
        final label = s.source.substring(s.pos, endArrow).trim();
        s.pos = endArrow + 3;
        return _ParsedEdge(label: label, hasArrow: true, dashed: true);
      }
      if (endPlain >= 0) {
        final label = s.source.substring(s.pos, endPlain).trim();
        s.pos = endPlain + 2;
        return _ParsedEdge(label: label, hasArrow: false, dashed: true);
      }
      s.pos = start;
      return null;
    }

    // Labeled thick: == <label> ==> or == <label> ===
    if (s.match('==')) {
      final endArrow = s.source.indexOf('==>', s.pos);
      final endPlain = s.source.indexOf('===', s.pos);
      if (endArrow >= 0 && (endPlain < 0 || endArrow <= endPlain)) {
        final label = s.source.substring(s.pos, endArrow).trim();
        s.pos = endArrow + 3;
        return _ParsedEdge(label: label, hasArrow: true, thick: true);
      }
      if (endPlain >= 0) {
        final label = s.source.substring(s.pos, endPlain).trim();
        s.pos = endPlain + 3;
        return _ParsedEdge(label: label, hasArrow: false, thick: true);
      }
      s.pos = start;
      return null;
    }

    s.pos = start;
    return null;
  }

  String _readBracketBody(String s) {
    final open = s.indexOf('[');
    if (open < 0) return s;
    final close = s.lastIndexOf(']');
    if (close < 0 || close < open) return s.substring(open + 1);
    return _unquote(s.substring(open + 1, close).trim());
  }

  String _unquote(String s) {
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}

// -----------------------------------------------------------------------------
// Emitter
// -----------------------------------------------------------------------------

String _emitMermaid(FlowGraph graph) {
  final buffer = StringBuffer();
  buffer.writeln('flowchart ${_directionToMermaid(graph.suggestedDirection)}');

  final declared = <String>{};

  void emitGroup(FlowGraphGroup g, String indent) {
    if (g.label.isNotEmpty && g.label != g.id) {
      buffer.writeln('$indent    subgraph ${g.id}[${g.label}]');
    } else {
      buffer.writeln('$indent    subgraph ${g.id}');
    }
    for (final childId in g.childGroupIds) {
      final child = graph.groups[childId];
      if (child != null) {
        emitGroup(child, '$indent    ');
      }
    }
    final nodeIds = {
      ...g.nodeIds,
      for (final n in graph.nodes.values)
        if (n.groupId == g.id) n.id,
    };
    for (final nodeId in nodeIds) {
      final node = graph.nodes[nodeId];
      if (node != null && declared.add(node.id)) {
        buffer.writeln('$indent        ${_emitNode(node)}');
      }
    }
    buffer.writeln('$indent    end');
  }

  for (final g in graph.groups.values) {
    if (g.parentId == null || !graph.groups.containsKey(g.parentId)) {
      emitGroup(g, '');
    }
  }

  for (final e in graph.edges.values) {
    final src = graph.nodes[e.source];
    if (src != null && declared.add(src.id)) {
      buffer.writeln('    ${_emitNode(src)}');
    }
    final tgt = graph.nodes[e.target];
    if (tgt != null && declared.add(tgt.id)) {
      buffer.writeln('    ${_emitNode(tgt)}');
    }
    buffer.writeln('    ${e.source} ${_emitEdge(e)} ${e.target}');
  }

  for (final n in graph.nodes.values) {
    if (declared.add(n.id)) {
      buffer.writeln('    ${_emitNode(n)}');
    }
  }

  return buffer.toString();
}

String _directionToMermaid(FlowLayoutDirection d) {
  switch (d) {
    case FlowLayoutDirection.topToBottom:
      return 'TD';
    case FlowLayoutDirection.bottomToTop:
      return 'BT';
    case FlowLayoutDirection.leftToRight:
      return 'LR';
    case FlowLayoutDirection.rightToLeft:
      return 'RL';
  }
}

String _emitNode(FlowGraphNode n) {
  if (n.label.isEmpty && n.shape == 'rectangle') return n.id;
  final l = n.label.replaceAll('"', r'\"');
  switch (n.shape) {
    case 'rounded':
      return '${n.id}("$l")';
    case 'circle':
      return '${n.id}(("$l"))';
    case 'diamond':
      return '${n.id}{"$l"}';
    case 'hexagon':
      return '${n.id}{{"$l"}}';
    case 'subroutine':
      return '${n.id}[["$l"]]';
    case 'cylinder':
      return '${n.id}[("$l")]';
    case 'asymmetric':
      return '${n.id}>"$l"]';
    case 'rectangle':
    default:
      return '${n.id}["$l"]';
  }
}

String _emitEdge(FlowGraphEdge e) {
  final arrow = e.targetArrow != FlowArrowHead.none;
  if (e.dashed) {
    if (e.label.isEmpty) return arrow ? '-.->' : '-.-';
    return '-.${e.label}.${arrow ? '->' : '-'}';
  }
  if (e.thick) {
    if (e.label.isEmpty) return arrow ? '==>' : '===';
    return '==${e.label}=${arrow ? '=>' : '='}';
  }
  if (e.label.isEmpty) return arrow ? '-->' : '---';
  return '--${e.label}--${arrow ? '>' : '-'}';
}

// -----------------------------------------------------------------------------
// Internal helpers
// -----------------------------------------------------------------------------

class _NodeRef {
  _NodeRef({
    required this.id,
    required this.label,
    required this.shape,
    required this.isBare,
  });
  final String id;
  final String label;
  final String shape;
  final bool isBare;
}

class _ParsedEdge {
  const _ParsedEdge({
    required this.label,
    required this.hasArrow,
    this.dashed = false,
    this.thick = false,
  });
  final String label;
  final bool hasArrow;
  final bool dashed;
  final bool thick;
}

class _ShapeAndLabel {
  _ShapeAndLabel(this.shape, this.label);
  final String shape;
  final String label;
}

class _GroupBuilder {
  _GroupBuilder({
    required this.id,
    required this.label,
    required this.parentId,
  });
  final String id;
  final String label;
  final String? parentId;
  final List<String> nodeIds = [];
  final List<String> childGroupIds = [];
}

class _Scanner {
  _Scanner(this.source);
  final String source;
  int pos = 0;

  bool get atEnd => pos >= source.length;

  void skipWhitespace() {
    while (pos < source.length && (source[pos] == ' ' || source[pos] == '\t')) {
      pos++;
    }
  }

  bool match(String literal) {
    if (source.startsWith(literal, pos)) {
      pos += literal.length;
      return true;
    }
    return false;
  }

  String readIdentifier() {
    final start = pos;
    while (pos < source.length && _isIdentifierChar(source[pos])) {
      if (source.startsWith('-->', pos) ||
          source.startsWith('---', pos) ||
          source.startsWith('-.', pos) ||
          source.startsWith('==', pos) ||
          source.startsWith('--', pos)) {
        break;
      }
      pos++;
    }
    return source.substring(start, pos);
  }

  String? readUntil(String terminator) {
    final idx = source.indexOf(terminator, pos);
    if (idx < 0) return null;
    final out = source.substring(pos, idx);
    pos = idx + terminator.length;
    return out;
  }

  static bool _isIdentifierChar(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) || // 0-9
        (code >= 0x41 && code <= 0x5A) || // A-Z
        (code >= 0x61 && code <= 0x7A) || // a-z
        c == '_' ||
        c == '-';
  }
}

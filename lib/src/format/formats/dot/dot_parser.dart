import 'package:flow_core/flow_core.dart';

/// Recursive-descent parser for Graphviz DOT.
class DotParser {
  DotParser(this.tokens);

  final List<DotToken> tokens;
  int _pos = 0;

  // Accumulation state.
  final _nodes = <String, _NodeAcc>{};
  final _edges = <FlowGraphEdge>[];
  final _groups = <String, _GroupAcc>{};
  final _graphAttrsStack = <Map<String, String>>[{}];
  final _nodeDefaultsStack = <Map<String, String>>[{}];
  final _edgeDefaultsStack = <Map<String, String>>[{}];
  final _clusterStack = <String>[];
  final _subgraphNodesStack = <Set<String>>[];
  int _edgeCounter = 0;
  bool _directed = true;
  FlowLayoutDirection _direction = FlowLayoutDirection.topToBottom;

  DotToken get _cur => tokens[_pos];

  DotToken _advance() => tokens[_pos++];

  bool _check(DotTokenType t) => _cur.type == t;

  bool _checkIdentifier(String v) =>
      _cur.type == DotTokenType.identifier && _cur.value == v;

  DotTokenType _peek(int offset) {
    final i = _pos + offset;
    return i < tokens.length ? tokens[i].type : DotTokenType.eof;
  }

  bool _match(DotTokenType t) {
    if (_check(t)) {
      _pos++;
      return true;
    }
    return false;
  }

  void _expect(DotTokenType t) {
    if (!_match(t)) {
      throw FormatException(
        'Expected $t at position ${_cur.position}, '
        'got ${_cur.type} "${_cur.value}"',
      );
    }
  }

  FlowGraph parse() {
    if (_checkIdentifier('strict')) _advance();

    if (_cur.type != DotTokenType.identifier) {
      throw FormatException(
        'Expected "graph" or "digraph" at position ${_cur.position}',
      );
    }
    final kind = _cur.value;
    if (kind == 'digraph') {
      _directed = true;
    } else if (kind == 'graph') {
      _directed = false;
    } else {
      throw FormatException('Expected "graph" or "digraph", got "$kind"');
    }
    _advance();

    if (_cur.type == DotTokenType.identifier) _advance();

    _expect(DotTokenType.lbrace);
    _parseStmtList();
    _expect(DotTokenType.rbrace);

    final rd = _graphAttrsStack.first['rankdir'];
    if (rd != null) _direction = _parseRankdir(rd);

    return _build();
  }

  void _parseStmtList() {
    while (!_check(DotTokenType.rbrace) && !_check(DotTokenType.eof)) {
      _parseStmt();
      if (_check(DotTokenType.semicolon)) _advance();
    }
  }

  void _parseStmt() {
    // Graph attribute: ID '=' ID
    if (_isIdToken(_cur.type) && _peek(1) == DotTokenType.equals) {
      final key = _advance().value;
      _advance(); // =
      final value = _readIdValue();
      _graphAttrsStack.last[key] = value;
      return;
    }

    // attr_stmt: graph | node | edge attr_list
    if (_check(DotTokenType.identifier)) {
      final kw = _cur.value;
      if ((kw == 'graph' || kw == 'node' || kw == 'edge') &&
          _peek(1) == DotTokenType.lbracket) {
        _advance();
        final attrs = _parseAttrList();
        switch (kw) {
          case 'graph':
            _graphAttrsStack.last.addAll(attrs);
            break;
          case 'node':
            _nodeDefaultsStack.last.addAll(attrs);
            break;
          case 'edge':
            _edgeDefaultsStack.last.addAll(attrs);
            break;
        }
        return;
      }
    }

    // Standalone subgraph.
    // if (_checkIdentifier('subgraph') || _check(DotTokenType.lbrace)) {
    //   _parseSubgraph();
    //   return;
    // }

    _parseNodeOrEdge();
  }

  void _parseNodeOrEdge() {
    final startsWithSubgraph =
        _checkIdentifier('subgraph') || _check(DotTokenType.lbrace);

    var left = _parseEndpoint();

    if (_check(DotTokenType.edgeDirected) ||
        _check(DotTokenType.edgeUndirected)) {
      while (_check(DotTokenType.edgeDirected) ||
          _check(DotTokenType.edgeUndirected)) {
        _advance();

        final right = _parseEndpoint();
        final attrs = _check(DotTokenType.lbracket)
            ? _parseAttrList()
            : const <String, String>{};

        for (final source in left) {
          for (final target in right) {
            _addEdge(source, target, attrs);
          }
        }

        left = right;
      }
    } else if (!startsWithSubgraph) {
      final attrs = _check(DotTokenType.lbracket)
          ? _parseAttrList()
          : const <String, String>{};

      for (final endpoint in left) {
        _declareNode(endpoint.id, attrs);
      }
    }
  }

  List<_Endpoint> _parseEndpoint() {
    if (_check(DotTokenType.lbrace) || _checkIdentifier('subgraph')) {
      final ids = _parseSubgraph();
      return [for (final id in ids) _Endpoint(id, null)];
    }

    final id = _readIdValue();
    String? port;
    if (_check(DotTokenType.colon)) {
      _advance();
      final first = _readIdValue();
      if (!_isCompassPoint(first)) {
        port = first;
        if (_check(DotTokenType.colon)) {
          _advance();
          _readIdValue();
        }
      }
    }
    return [_Endpoint(id, port)];
  }

  List<String> _parseSubgraph() {
    if (_checkIdentifier('subgraph')) _advance();

    String? name;
    if (_cur.type == DotTokenType.identifier ||
        _cur.type == DotTokenType.quotedString) {
      name = _advance().value;
    }
    _expect(DotTokenType.lbrace);

    String? groupId;
    if (name != null && (name == 'cluster' || name.startsWith('cluster_'))) {
      groupId = name;
      _clusterStack.add(groupId);
      _groups.putIfAbsent(groupId, () => _GroupAcc(id: groupId!));
    }

    _graphAttrsStack.add({});
    _nodeDefaultsStack.add({..._nodeDefaultsStack.last});
    _edgeDefaultsStack.add({..._edgeDefaultsStack.last});
    final declared = <String>{};
    _subgraphNodesStack.add(declared);

    _parseStmtList();
    _expect(DotTokenType.rbrace);

    _subgraphNodesStack.removeLast();
    _nodeDefaultsStack.removeLast();
    _edgeDefaultsStack.removeLast();
    final localAttrs = _graphAttrsStack.removeLast();

    if (groupId != null) {
      _clusterStack.removeLast();
      final label = localAttrs['label'] ?? '';
      _groups[groupId] = _groups[groupId]!.withLabel(label);
    }

    if (_subgraphNodesStack.isNotEmpty) {
      _subgraphNodesStack.last.addAll(declared);
    }

    return declared.toList();
  }

  void _declareNode(String id, Map<String, String> attrs) {
    if (_subgraphNodesStack.isNotEmpty) {
      _subgraphNodesStack.last.add(id);
    }

    final existing = _nodes[id];
    final mergedAttrs = <String, String>{
      ..._nodeDefaultsStack.last,
      ...?existing?.attrs,
      ...attrs,
    };

    final acc = existing ?? _NodeAcc(id: id);
    acc.attrs = mergedAttrs;

    if (_clusterStack.isNotEmpty) {
      final gid = _clusterStack.last;
      final grp = _groups.putIfAbsent(gid, () => _GroupAcc(id: gid));
      if (!grp.nodeIds.contains(id)) grp.nodeIds.add(id);
      acc.groupId ??= gid;
    }

    _nodes[id] = acc;
  }

  void _addEdge(_Endpoint a, _Endpoint b, Map<String, String> attrs) {
    if (_subgraphNodesStack.isNotEmpty) {
      _subgraphNodesStack.last
        ..add(a.id)
        ..add(b.id);
    }
    _declareNode(a.id, const {});
    _declareNode(b.id, const {});

    final merged = <String, String>{
      ..._edgeDefaultsStack.last,
      ...attrs,
    };

    _edgeCounter++;
    final styleParts =
        (merged['style'] ?? '').split(',').map((s) => s.trim()).toSet();

    _edges.add(FlowGraphEdge(
      id: 'e$_edgeCounter',
      source: a.id,
      target: b.id,
      sourcePort: a.port,
      targetPort: b.port,
      label: merged['label'] ?? '',
      kind: FlowEdgeKind.flow,
      sourceArrow: _arrowFrom(merged, isSource: true),
      targetArrow: _arrowFrom(merged, isSource: false),
      dashed: styleParts.contains('dashed') || styleParts.contains('dotted'),
      thick: (double.tryParse(merged['penwidth'] ?? '1') ?? 1) >= 2,
      meta: merged,
    ));
  }

  Map<String, String> _parseAttrList() {
    final out = <String, String>{};
    while (_check(DotTokenType.lbracket)) {
      _advance();
      while (!_check(DotTokenType.rbracket) && !_check(DotTokenType.eof)) {
        if (_check(DotTokenType.semicolon) || _check(DotTokenType.comma)) {
          _advance();
          continue;
        }
        if (!_isIdToken(_cur.type)) break;
        final key = _advance().value;
        var value = 'true';
        if (_check(DotTokenType.equals)) {
          _advance();
          value = _readIdValue();
        }
        out[key] = value;
      }
      _expect(DotTokenType.rbracket);
    }
    return out;
  }

  String _readIdValue() {
    if (_isIdToken(_cur.type)) return _advance().value;
    throw FormatException(
      'Expected identifier at position ${_cur.position}, '
      'got ${_cur.type} "${_cur.value}"',
    );
  }

  bool _isIdToken(DotTokenType t) =>
      t == DotTokenType.identifier ||
      t == DotTokenType.quotedString ||
      t == DotTokenType.htmlString ||
      t == DotTokenType.number;

  FlowLayoutDirection _parseRankdir(String v) {
    switch (v.toUpperCase()) {
      case 'TB':
      case 'TD':
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

  FlowArrowHead _arrowFrom(Map<String, String> attrs, {required bool isSource}) {
    final dir = attrs['dir'] ?? 'forward';

    if (dir == 'none') return FlowArrowHead.none;
    if (isSource && dir == 'forward') return FlowArrowHead.none;
    if (!isSource && dir == 'back') return FlowArrowHead.none;
    if (isSource && dir == 'back' && !attrs.containsKey('arrowtail')) {
      return FlowArrowHead.filledArrow;
    }
    if (!isSource && dir == 'forward' && !attrs.containsKey('arrowhead')) {
      return FlowArrowHead.filledArrow;
    }

    final v = attrs[isSource ? 'arrowtail' : 'arrowhead'];
    if (v == null) return FlowArrowHead.none;
    return _parseArrow(v);
  }

  FlowArrowHead _parseArrow(String v) {
    switch (v.toLowerCase()) {
      case 'none':
        return FlowArrowHead.none;
      case 'normal':
        return FlowArrowHead.filledArrow;
      case 'inv':
        return FlowArrowHead.filledArrow;
      case 'dot':
        return FlowArrowHead.filledCircle;
      case 'odot':
        return FlowArrowHead.circle;
      case 'invdot':
        return FlowArrowHead.filledCircle;
      case 'invodot':
        return FlowArrowHead.circle;
      case 'tee':
        return FlowArrowHead.bar;
      case 'empty':
        return FlowArrowHead.hollowArrow;
      case 'invempty':
        return FlowArrowHead.hollowArrow;
      case 'diamond':
        return FlowArrowHead.filledDiamond;
      case 'odiamond':
        return FlowArrowHead.diamond;
      case 'ediamond':
        return FlowArrowHead.diamond;
      case 'crow':
        return FlowArrowHead.cross;
      case 'box':
        return FlowArrowHead.filledSquare;
      case 'obox':
        return FlowArrowHead.square;
      case 'open':
        return FlowArrowHead.arrow;
      case 'halfopen':
        return FlowArrowHead.arrow;
      case 'vee':
        return FlowArrowHead.arrow;
    }
    return FlowArrowHead.filledArrow;
  }

  static bool _isCompassPoint(String s) {
    switch (s) {
      case 'n':
      case 's':
      case 'e':
      case 'w':
      case 'ne':
      case 'nw':
      case 'se':
      case 'sw':
      case 'c':
      case '_':
        return true;
    }
    return false;
  }

  FlowGraph _build() {
    final nodes = <String, FlowGraphNode>{};
    for (final entry in _nodes.entries) {
      final acc = entry.value;
      final attrs = acc.attrs;
      nodes[entry.key] = FlowGraphNode(
        id: entry.key,
        label: attrs['label'] ?? entry.key,
        shape: _shapeFromAttrs(attrs),
        groupId: acc.groupId,
        meta: attrs,
      );
    }

    final edges = <String, FlowGraphEdge>{};
    for (final e in _edges) {
      edges[e.id] = e;
    }

    final groups = <String, FlowGraphGroup>{};
    for (final entry in _groups.entries) {
      final g = entry.value;
      groups[entry.key] = FlowGraphGroup(
        id: g.id,
        label: g.label.isEmpty ? g.id : g.label,
        nodeIds: List.unmodifiable(g.nodeIds),
      );
    }

    return FlowGraph(
      nodes: nodes,
      edges: edges,
      groups: groups,
      suggestedDirection: _direction,
      suggestedLayout: 'layered',
      meta: {'source': 'dot', 'directed': _directed},
    );
  }

  String _shapeFromAttrs(Map<String, String> attrs) {
    final s = attrs['shape'];
    if (s == null || s.isEmpty) return 'rectangle';
    switch (s.toLowerCase()) {
      case 'box':
      case 'rect':
      case 'rectangle':
      case 'square':
        return 'rectangle';
      case 'ellipse':
      case 'oval':
      case 'egg':
        return 'ellipse';
      case 'circle':
      case 'doublecircle':
      case 'point':
        return 'circle';
      case 'diamond':
      case 'mdiamond':
        return 'diamond';
      case 'msquare':
        return 'rectangle';
      case 'hexagon':
        return 'hexagon';
      case 'cylinder':
        return 'cylinder';
      case 'note':
        return 'note';
      case 'tab':
      case 'folder':
      case 'box3d':
      case 'component':
      case 'record':
      case 'mrecord':
      case 'house':
      case 'invhouse':
        return 'rectangle';
      case 'parallelogram':
        return 'parallelogram';
      case 'triangle':
      case 'invtriangle':
        return 'triangle';
      case 'trapezium':
      case 'invtrapezium':
        return 'trapezoid';
      case 'pentagon':
        return 'pentagon';
      case 'septagon':
        return 'polygon';
      case 'star':
        return 'star';
      case 'plaintext':
      case 'plain':
      case 'none':
        return 'text';
    }
    return 'rectangle';
  }
}

class _Endpoint {
  _Endpoint(this.id, this.port);
  final String id;
  final String? port;
}

class _NodeAcc {
  _NodeAcc({required this.id});
  final String id;
  Map<String, String> attrs = const {};
  String? groupId;
}

class _GroupAcc {
  _GroupAcc({required this.id});
  final String id;
  String label = '';
  final List<String> nodeIds = [];

  _GroupAcc withLabel(String value) {
    final g = _GroupAcc(id: id)
      ..label = value
      ..nodeIds.addAll(nodeIds);
    return g;
  }
}
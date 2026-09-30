import '../../../layout/flow_layout_direction.dart';
import '../../../model/flow_arrow_head.dart';
import '../../flow_graph.dart';

/// Emits a [FlowGraph] as Graphviz DOT.
class DotEmitter {
  DotEmitter(this.graph);

  final FlowGraph graph;

  String emit() {
    final directed = (graph.meta['directed'] as bool?) ?? true;
    final op = directed ? '->' : '--';

    final b = StringBuffer();
    b.writeln(directed ? 'digraph G {' : 'graph G {');
    b.writeln('  rankdir=${_rankdir(graph.suggestedDirection)};');

    for (final g in graph.groups.values) {
      b.writeln();
      b.writeln('  subgraph ${_dotId(g.id)} {');
      if (g.label.isNotEmpty && g.label != g.id) {
        b.writeln('    label="${_escape(g.label)}";');
      }
      for (final id in g.nodeIds) {
        final n = graph.nodes[id];
        if (n == null) continue;
        b.writeln('    ${_nodeDecl(n)}');
      }
      b.writeln('  }');
    }

    for (final n in graph.nodes.values) {
      if (n.groupId != null) continue;
      b.writeln('  ${_nodeDecl(n)}');
    }

    if (graph.edges.isNotEmpty) b.writeln();
    for (final e in graph.edges.values) {
      b.writeln('  ${_edgeDecl(e, op)}');
    }

    b.writeln('}');
    return b.toString();
  }

  String _nodeDecl(FlowGraphNode n) {
    final parts = <String>[];
    if (n.label.isNotEmpty && n.label != n.id) {
      parts.add('label="${_escape(n.label)}"');
    }
    final shape = _dotShape(n.shape);
    if (shape != null) parts.add('shape=$shape');
    final body = parts.isEmpty ? '' : ' [${parts.join(', ')}]';
    return '${_dotId(n.id)}$body;';
  }

  String _edgeDecl(FlowGraphEdge e, String op) {
    final src = e.sourcePort == null
        ? _dotId(e.source)
        : '${_dotId(e.source)}:${_dotId(e.sourcePort!)}';
    final tgt = e.targetPort == null
        ? _dotId(e.target)
        : '${_dotId(e.target)}:${_dotId(e.targetPort!)}';

    final parts = <String>[];
    if (e.label.isNotEmpty) parts.add('label="${_escape(e.label)}"');
    if (e.dashed) parts.add('style=dashed');
    if (e.thick) parts.add('penwidth=2');
    if (e.targetArrow == FlowArrowHead.none) parts.add('arrowhead=none');
    if (e.sourceArrow != FlowArrowHead.none) parts.add('arrowtail=normal');

    final body = parts.isEmpty ? '' : ' [${parts.join(', ')}]';
    return '$src $op $tgt$body;';
  }

  String _rankdir(FlowLayoutDirection d) {
    switch (d) {
      case FlowLayoutDirection.topToBottom:
        return 'TB';
      case FlowLayoutDirection.bottomToTop:
        return 'BT';
      case FlowLayoutDirection.leftToRight:
        return 'LR';
      case FlowLayoutDirection.rightToLeft:
        return 'RL';
    }
  }

  String? _dotShape(String shape) {
    switch (shape) {
      case 'rectangle':
        return 'box';
      case 'rounded':
        return 'box';
      case 'circle':
        return 'circle';
      case 'ellipse':
        return 'ellipse';
      case 'diamond':
        return 'diamond';
      case 'hexagon':
        return 'hexagon';
      case 'cylinder':
        return 'cylinder';
      case 'note':
        return 'note';
      case 'parallelogram':
        return 'parallelogram';
      case 'triangle':
        return 'triangle';
      case 'trapezoid':
        return 'trapezium';
      case 'pentagon':
        return 'pentagon';
      case 'star':
        return 'star';
      case 'polygon':
        return 'septagon';
      case 'text':
        return 'plaintext';
    }
    return null;
  }

  String _dotId(String id) {
    if (RegExp(r'^[A-Za-z_][A-Za-z_0-9]*$').hasMatch(id)) return id;
    return '"${_escape(id)}"';
  }

  static String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n');
}
import '../../flow_format.dart';
import '../../flow_format_options.dart';
import '../../flow_graph.dart';
import 'dot_emitter.dart';
import 'dot_lexer.dart';
import 'dot_parser.dart';

/// Graphviz DOT parser and emitter.
///
/// Supports:
/// - `graph` and `digraph`, optional `strict`, optional graph name.
/// - Node, edge, and graph attribute lists.
/// - Default attributes via `node [...]`, `edge [...]`, `graph [...]`.
/// - Edge chains: `A -> B -> C`.
/// - Subgraphs, including `cluster_*` for grouped output.
/// - Subgraph endpoints: `{ A B } -> C`.
/// - Ports: `A:out -> B:in`, with optional compass points.
/// - `rankdir=TB|BT|LR|RL` mapped to a layout direction.
class GraphvizDotFormat extends FlowFormat {
  const GraphvizDotFormat();

  @override
  String get id => 'dot';

  @override
  String get name => 'Graphviz DOT';

  @override
  List<String> get extensions => const ['.dot', '.gv'];

  @override
  bool canParse(String content) {
    final head = content.length > 400 ? content.substring(0, 400) : content;
    return RegExp(r'^\s*(strict\s+)?(di)?graph\b').hasMatch(head);
  }

  @override
  Future<FlowGraph> parse(String content, {FlowFormatOptions? options}) async {
    final tokens = DotLexer(content).tokenize();
    return DotParser(tokens).parse();
  }

  @override
  Future<String> emit(FlowGraph graph, {FlowFormatOptions? options}) async {
    return DotEmitter(graph).emit();
  }
}
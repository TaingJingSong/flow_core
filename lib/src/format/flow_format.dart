import 'flow_format_options.dart';
import 'flow_graph.dart';

/// A parser/emitter for one text format.
///
/// Implementations must be pure: parsing the same content twice yields
/// equal graphs; emitting the same graph twice yields equal strings.
abstract class FlowFormat {
  const FlowFormat();

  /// Stable identifier, e.g. `"mermaid"`.
  String get id;

  /// Human-readable name for UI.
  String get name;

  /// File extensions including the leading dot, e.g. `['.mmd', '.mermaid']`.
  List<String> get extensions;

  /// Cheap heuristic. Must not throw and must not be a full parse.
  bool canParse(String content);

  /// Parses [content] into a semantic [FlowGraph].
  Future<FlowGraph> parse(String content, {FlowFormatOptions? options});

  /// Emits [graph] back to this format.
  Future<String> emit(FlowGraph graph, {FlowFormatOptions? options});
}

/// Registry of [FlowFormat]s keyed by id, with detection support.
class FlowFormatRegistry {
  FlowFormatRegistry({bool withDefaults = true}) {
    if (withDefaults) {
      // Core ships no formats. Callers register Mermaid, draw.io, etc.
    }
  }

  final Map<String, FlowFormat> _byId = <String, FlowFormat>{};
  final List<FlowFormat> _order = <FlowFormat>[];

  Iterable<FlowFormat> get formats => List.unmodifiable(_order);

  void register(FlowFormat format) {
    if (!_byId.containsKey(format.id)) _order.add(format);
    _byId[format.id] = format;
  }

  void unregister(String id) {
    final f = _byId.remove(id);
    if (f != null) _order.remove(f);
  }

  FlowFormat? byId(String id) => _byId[id];

  FlowFormat? byExtension(String ext) {
    final normalized = ext.startsWith('.') ? ext : '.$ext';
    for (final f in _order) {
      for (final e in f.extensions) {
        if (e.toLowerCase() == normalized.toLowerCase()) return f;
      }
    }
    return null;
  }

  /// First registered format that claims to parse [content], or null.
  FlowFormat? detect(String content) {
    for (final f in _order) {
      if (f.canParse(content)) return f;
    }
    return null;
  }
}
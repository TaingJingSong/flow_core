import '../model/flow_document.dart';
import 'flow_format.dart';
import 'flow_format_options.dart';
import 'graph_from_document.dart';

/// Emits a [FlowDocument] as text.
class FlowExportPipeline {
  const FlowExportPipeline({required this.registry});

  final FlowFormatRegistry registry;

  Future<String> exportAs(
    FlowDocument document,
    String formatId, {
    FlowFormatOptions? options,
  }) async {
    final format = registry.byId(formatId);
    if (format == null) {
      throw ArgumentError('Unknown format id: $formatId');
    }
    final graph = documentToFlowGraph(document);
    return format.emit(graph, options: options);
  }
}
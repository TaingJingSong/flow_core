import '../model/flow_document.dart';
import 'flow_format.dart';
import 'flow_format_options.dart';
import 'graph_converter.dart';

/// Parses text into a [FlowDocument].
class FlowImportPipeline {
  FlowImportPipeline({
    required this.registry,
    FlowGraphConverter? converter,
  }) : converter = converter ?? const FlowGraphConverter();

  final FlowFormatRegistry registry;
  final FlowGraphConverter converter;

  /// Parses [content] using the format with [formatId].
  Future<FlowDocument> importAs(
    String content,
    String formatId, {
    FlowFormatOptions? options,
    bool runLayout = true,
    String documentName = 'Untitled',
  }) async {
    final format = registry.byId(formatId);
    if (format == null) {
      throw ArgumentError('Unknown format id: $formatId');
    }
    final graph = await format.parse(content, options: options);
    return converter.toDocument(
      graph,
      runLayout: runLayout,
      documentName: documentName,
    );
  }

  /// Detects the format and parses [content].
  Future<FlowDocument> importAuto(
    String content, {
    FlowFormatOptions? options,
    bool runLayout = true,
    String documentName = 'Untitled',
  }) async {
    final format = registry.detect(content);
    if (format == null) {
      throw const FormatException(
        'No registered format can parse this content.',
      );
    }
    final graph = await format.parse(content, options: options);
    return converter.toDocument(
      graph,
      runLayout: runLayout,
      documentName: documentName,
    );
  }
}
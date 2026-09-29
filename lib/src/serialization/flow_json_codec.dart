import 'dart:convert';

import '../model/flow_document.dart';
import 'codecs/document_codec.dart';
import 'flow_migrations.dart';

/// Encodes and decodes [FlowDocument] to and from JSON.
///
/// The wire format is versioned via `schemaVersion`. Older documents are
/// upgraded automatically by [FlowMigrations]. Newer documents throw a
/// [FlowMigrationException].
class FlowJsonCodec {
  const FlowJsonCodec();

  /// Encodes [document] into a JSON-compatible map.
  Map<String, Object?> encode(FlowDocument document) =>
      DocumentCodec.encode(document);

  /// Decodes a JSON-compatible map into a [FlowDocument].
  ///
  /// Runs migrations first, so any supported older version works.
  FlowDocument decode(Map<String, Object?> json) =>
      DocumentCodec.decode(FlowMigrations.migrate(json));

  /// Encodes to a JSON string. Set [pretty] for human-readable output.
  String encodeToString(FlowDocument document, {bool pretty = false}) {
    final map = encode(document);
    if (!pretty) return jsonEncode(map);
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Decodes a JSON string into a [FlowDocument].
  FlowDocument decodeFromString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Root of flow document must be an object.');
    }
    final map = <String, Object?>{};
    decoded.forEach((k, v) => map[k.toString()] = v);
    return decode(map);
  }
}
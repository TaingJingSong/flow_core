import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'flow_id.dart';
import 'flow_metadata.dart';
import 'flow_page.dart';

const _listEq = ListEquality<FlowPage>();

/// The top-level container: a collection of pages plus metadata.
///
/// This is the single source of truth for a diagram. Every format
/// (JSON, Mermaid, draw.io, DOT, ...) either parses into this or emits
/// from it.
@immutable
class FlowDocument {
  FlowDocument({
    required this.id,
    this.name = 'Untitled',
    List<FlowPage>? pages,
    this.metadata = const FlowMetadata(),
    this.schemaVersion = FlowDocument.currentSchemaVersion,
  }) : pages = List.unmodifiable(pages ?? <FlowPage>[]);

  factory FlowDocument.empty({FlowId? id, String name = 'Untitled'}) {
    final docId = id ?? const FlowId('doc');
    return FlowDocument(
      id: docId,
      name: name,
      pages: [FlowPage.empty(id: const FlowId('page_1'))],
    );
  }

  /// Increment when the JSON schema changes in a breaking way.
  /// Pair every bump with a migration in `FlowMigrations`.
  static const int currentSchemaVersion = 1;

  final FlowId id;
  final String name;
  final List<FlowPage> pages;
  final FlowMetadata metadata;
  final int schemaVersion;

  FlowPage? get firstPage => pages.isEmpty ? null : pages.first;

  FlowPage? pageById(FlowId pageId) {
    for (final p in pages) {
      if (p.id == pageId) return p;
    }
    return null;
  }

  FlowDocument copyWith({
    FlowId? id,
    String? name,
    List<FlowPage>? pages,
    FlowMetadata? metadata,
    int? schemaVersion,
  }) =>
      FlowDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        pages: pages ?? this.pages,
        metadata: metadata ?? this.metadata,
        schemaVersion: schemaVersion ?? this.schemaVersion,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowDocument &&
          other.id == id &&
          other.name == name &&
          _listEq.equals(other.pages, pages) &&
          other.metadata == metadata &&
          other.schemaVersion == schemaVersion;

  @override
  int get hashCode =>
      Object.hash(id, name, _listEq.hash(pages), metadata, schemaVersion);

  @override
  String toString() =>
      'FlowDocument($id, "$name", pages: ${pages.length})';
}
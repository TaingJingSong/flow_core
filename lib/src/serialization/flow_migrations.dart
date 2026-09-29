import 'package:meta/meta.dart';

import '../model/flow_document.dart';

/// Raised when a document cannot be migrated to the current schema.
class FlowMigrationException implements Exception {
  const FlowMigrationException(this.message);

  final String message;

  @override
  String toString() => 'FlowMigrationException: $message';
}

/// Upgrades a decoded document map to the latest [FlowDocument] schema.
///
/// When you bump [FlowDocument.currentSchemaVersion], add a branch here
/// that transforms the previous version into the next one. Chain them:
/// v1 -> v2 -> v3 -> ... so any old file can be read.
@internal
abstract final class FlowMigrations {
  static const int latest = FlowDocument.currentSchemaVersion;

  /// Mutates nothing; returns a new map at [latest].
  static Map<String, Object?> migrate(Map<String, Object?> json) {
    final raw = json['schemaVersion'];
    if (raw is! int) {
      throw const FlowMigrationException(
        'Missing or invalid "schemaVersion".',
      );
    }

    if (raw > latest) {
      throw FlowMigrationException(
        'Document schemaVersion $raw is newer than supported $latest. '
        'Upgrade flow_core to open this file.',
      );
    }

    final current = raw;
    final data = json;

    // Future migrations go here, in ascending order.
    // Example:
    // if (current == 1) {
    //   data = _v1ToV2(data);
    //   current = 2;
    // }

    if (current != latest) {
      throw FlowMigrationException(
        'No migration path from schemaVersion $current to $latest.',
      );
    }

    return data;
  }
}
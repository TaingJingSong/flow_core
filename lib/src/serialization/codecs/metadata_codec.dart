import 'package:meta/meta.dart';

import '../../model/flow_metadata.dart';
import 'json_utils.dart';

@internal
abstract final class MetadataCodec {
  static Map<String, Object?> encode(FlowMetadata m) => {
        if (m.title != null) 'title': m.title,
        if (m.description != null) 'description': m.description,
        if (m.author != null) 'author': m.author,
        if (m.createdAt != null)
          'createdAt': m.createdAt!.toUtc().toIso8601String(),
        if (m.updatedAt != null)
          'updatedAt': m.updatedAt!.toUtc().toIso8601String(),
        if (m.tags.isNotEmpty) 'tags': m.tags.toList(),
        if (m.custom.isNotEmpty) 'custom': m.custom,
      };

  static FlowMetadata decode(Object? v) {
    if (v is! Map) return const FlowMetadata();
    return FlowMetadata(
      title: asStringOrNull(v['title']),
      description: asStringOrNull(v['description']),
      author: asStringOrNull(v['author']),
      createdAt: asDateTime(v['createdAt']),
      updatedAt: asDateTime(v['updatedAt']),
      tags: asStringSet(v['tags']),
      custom: asMap(v['custom']),
    );
  }
}
import 'package:meta/meta.dart';

import '../../model/flow_document.dart';
import '../../model/flow_id.dart';
import 'json_utils.dart';
import 'metadata_codec.dart';
import 'page_codec.dart';

@internal
abstract final class DocumentCodec {
  static Map<String, Object?> encode(FlowDocument d) => {
        'schemaVersion': d.schemaVersion,
        'id': d.id.value,
        'name': d.name,
        'metadata': MetadataCodec.encode(d.metadata),
        'pages': PageCodec.encodeList(d.pages),
      };

  static FlowDocument decode(Map<String, Object?> json) {
    return FlowDocument(
      id: FlowId(asString(json['id'], 'doc')),
      name: asString(json['name'], 'Untitled'),
      metadata: MetadataCodec.decode(json['metadata']),
      pages: PageCodec.decodeList(json['pages']),
      schemaVersion: asInt(
        json['schemaVersion'],
        FlowDocument.currentSchemaVersion,
      ),
    );
  }
}
import 'package:meta/meta.dart';

import '../../model/flow_port.dart';
import 'json_utils.dart';
import 'label_codec.dart';

@internal
abstract final class PortCodec {
  static Map<String, Object?> encode(FlowPort p) => {
        'name': p.name,
        'side': p.side.name,
        'kind': p.kind.name,
        'position': p.position,
        'isConnectable': p.isConnectable,
        if (p.label != null) 'label': LabelCodec.encode(p.label!),
      };

  static FlowPort decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Port must be a JSON object');
    }
    return FlowPort(
      name: asString(v['name']),
      side: asEnum(FlowPortSide.values, v['side'], FlowPortSide.center),
      kind: asEnum(FlowPortKind.values, v['kind'], FlowPortKind.bidirectional),
      position: asDouble(v['position'], 0.5),
      isConnectable: asBool(v['isConnectable'], true),
      label: LabelCodec.decodeOrNull(v['label']),
    );
  }

  static List<Map<String, Object?>> encodeList(List<FlowPort> ports) =>
      [for (final p in ports) encode(p)];

  static List<FlowPort> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
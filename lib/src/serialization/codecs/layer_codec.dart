import 'package:meta/meta.dart';

import '../../model/flow_id.dart';
import '../../model/flow_layer.dart';
import 'json_utils.dart';

@internal
abstract final class LayerCodec {
  static Map<String, Object?> encode(FlowLayer l) => {
        'id': l.id.value,
        'name': l.name,
        if (!l.visible) 'visible': l.visible,
        if (l.locked) 'locked': l.locked,
        if (l.zIndex != 0) 'zIndex': l.zIndex,
        if (l.opacity != 1.0) 'opacity': l.opacity,
      };

  static FlowLayer decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Layer must be a JSON object');
    }
    return FlowLayer(
      id: FlowId(asString(v['id'])),
      name: asString(v['name'], 'Layer'),
      visible: asBool(v['visible'], true),
      locked: asBool(v['locked']),
      zIndex: asInt(v['zIndex']),
      opacity: asDouble(v['opacity'], 1.0),
    );
  }

  static List<Map<String, Object?>> encodeList(Iterable<FlowLayer> layers) =>
      [for (final l in layers) encode(l)];

  static List<FlowLayer> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
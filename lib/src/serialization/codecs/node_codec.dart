import 'package:meta/meta.dart';

import '../../model/flow_id.dart';
import '../../model/flow_node.dart';
import 'json_utils.dart';
import 'label_codec.dart';
import 'port_codec.dart';
import 'primitives_codec.dart';
import 'style_codec.dart';

@internal
abstract final class NodeCodec {
  static Map<String, Object?> encode(FlowNode n) => {
        'id': n.id.value,
        'type': n.type,
        'rect': RectCodec.encode(n.rect),
        'style': StyleCodec.encode(n.style),
        if (n.label != null) 'label': LabelCodec.encode(n.label!),
        if (n.ports.isNotEmpty) 'ports': PortCodec.encodeList(n.ports),
        if (n.data.isNotEmpty) 'data': n.data,
        if (n.tags.isNotEmpty) 'tags': n.tags.toList(),
        if (n.meta.isNotEmpty) 'meta': n.meta,
        if (n.parentGroupId != null) 'parentGroupId': n.parentGroupId!.value,
        if (n.layerId != null) 'layerId': n.layerId!.value,
        if (n.namespace != null) 'namespace': n.namespace,
        if (n.zIndex != 0) 'zIndex': n.zIndex,
        if (n.locked) 'locked': n.locked,
        if (!n.visible) 'visible': n.visible,
        if (n.rotation != 0) 'rotation': n.rotation,
      };

  static FlowNode decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Node must be a JSON object');
    }
    return FlowNode(
      id: FlowId(asString(v['id'])),
      type: asString(v['type'], 'rectangle'),
      rect: RectCodec.decode(v['rect']),
      style: StyleCodec.decode(v['style']),
      label: LabelCodec.decodeOrNull(v['label']),
      ports: PortCodec.decodeList(v['ports']),
      data: asMap(v['data']),
      tags: asStringSet(v['tags']),
      meta: asStringMap(v['meta']),
      parentGroupId:
          v['parentGroupId'] == null ? null : FlowId(asString(v['parentGroupId'])),
      layerId: v['layerId'] == null ? null : FlowId(asString(v['layerId'])),
      namespace: asStringOrNull(v['namespace']),
      zIndex: asInt(v['zIndex']),
      locked: asBool(v['locked']),
      visible: asBool(v['visible'], true),
      rotation: asDouble(v['rotation']),
    );
  }

  static List<Map<String, Object?>> encodeList(Iterable<FlowNode> nodes) =>
      [for (final n in nodes) encode(n)];

  static List<FlowNode> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
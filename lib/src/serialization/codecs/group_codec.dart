import 'package:meta/meta.dart';

import '../../model/flow_group.dart';
import '../../model/flow_id.dart';
import 'json_utils.dart';
import 'label_codec.dart';
import 'primitives_codec.dart';
import 'style_codec.dart';

@internal
abstract final class GroupCodec {
  static Map<String, Object?> encode(FlowGroup g) => {
        'id': g.id.value,
        'rect': RectCodec.encode(g.rect),
        if (g.label != null) 'label': LabelCodec.encode(g.label!),
        if (g.childNodeIds.isNotEmpty)
          'childNodeIds': [for (final id in g.childNodeIds) id.value],
        if (g.childGroupIds.isNotEmpty)
          'childGroupIds': [for (final id in g.childGroupIds) id.value],
        'style': StyleCodec.encode(g.style),
        if (g.collapsed) 'collapsed': g.collapsed,
        if (g.parentGroupId != null) 'parentGroupId': g.parentGroupId!.value,
        if (g.layerId != null) 'layerId': g.layerId!.value,
        if (g.namespace != null) 'namespace': g.namespace,
        if (g.data.isNotEmpty) 'data': g.data,
        if (g.meta.isNotEmpty) 'meta': g.meta,
        if (g.zIndex != 0) 'zIndex': g.zIndex,
        if (g.locked) 'locked': g.locked,
        if (!g.visible) 'visible': g.visible,
      };

  static FlowGroup decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Group must be a JSON object');
    }
    return FlowGroup(
      id: FlowId(asString(v['id'])),
      rect: RectCodec.decode(v['rect']),
      label: LabelCodec.decodeOrNull(v['label']),
      childNodeIds: [
        for (final id in asStringList(v['childNodeIds'])) FlowId(id),
      ],
      childGroupIds: [
        for (final id in asStringList(v['childGroupIds'])) FlowId(id),
      ],
      style: StyleCodec.decode(v['style']),
      collapsed: asBool(v['collapsed']),
      parentGroupId:
          v['parentGroupId'] == null ? null : FlowId(asString(v['parentGroupId'])),
      layerId: v['layerId'] == null ? null : FlowId(asString(v['layerId'])),
      namespace: asStringOrNull(v['namespace']),
      data: asMap(v['data']),
      meta: asStringMap(v['meta']),
      zIndex: asInt(v['zIndex']),
      locked: asBool(v['locked']),
      visible: asBool(v['visible'], true),
    );
  }

  static List<Map<String, Object?>> encodeList(Iterable<FlowGroup> groups) =>
      [for (final g in groups) encode(g)];

  static List<FlowGroup> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
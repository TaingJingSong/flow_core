import 'package:meta/meta.dart';

import '../../model/flow_arrow_head.dart';
import '../../model/flow_edge.dart';
import '../../model/flow_edge_kind.dart';
import '../../model/flow_id.dart';
import 'json_utils.dart';
import 'label_codec.dart';
import 'primitives_codec.dart';
import 'style_codec.dart';

@internal
abstract final class EdgeCodec {
  static Map<String, Object?> encode(FlowEdge e) => {
        'id': e.id.value,
        'source': e.sourceNodeId.value,
        'target': e.targetNodeId.value,
        if (e.sourcePortName != null) 'sourcePort': e.sourcePortName,
        if (e.targetPortName != null) 'targetPort': e.targetPortName,
        'kind': e.kind.name,
        'routing': e.routing.name,
        if (e.waypoints.isNotEmpty)
          'waypoints': PointCodec.encodeList(e.waypoints),
        'sourceArrow': e.sourceArrow.name,
        'targetArrow': e.targetArrow.name,
        'style': StyleCodec.encode(e.style),
        if (e.label != null) 'label': LabelCodec.encode(e.label!),
        if (e.data.isNotEmpty) 'data': e.data,
        if (e.meta.isNotEmpty) 'meta': e.meta,
        if (e.namespace != null) 'namespace': e.namespace,
        if (e.zIndex != 0) 'zIndex': e.zIndex,
        if (e.locked) 'locked': e.locked,
        if (!e.visible) 'visible': e.visible,
      };

  static FlowEdge decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Edge must be a JSON object');
    }
    return FlowEdge(
      id: FlowId(asString(v['id'])),
      sourceNodeId: FlowId(asString(v['source'])),
      targetNodeId: FlowId(asString(v['target'])),
      sourcePortName: asStringOrNull(v['sourcePort']),
      targetPortName: asStringOrNull(v['targetPort']),
      kind: asEnum(FlowEdgeKind.values, v['kind'], FlowEdgeKind.flow),
      routing: asEnum(
        FlowEdgeRouting.values, v['routing'], FlowEdgeRouting.straight),
      waypoints: PointCodec.decodeList(v['waypoints']),
      sourceArrow: asEnum(
        FlowArrowHead.values, v['sourceArrow'], FlowArrowHead.none),
      targetArrow: asEnum(
        FlowArrowHead.values, v['targetArrow'], FlowArrowHead.filledArrow),
      style: StyleCodec.decode(v['style']),
      label: LabelCodec.decodeOrNull(v['label']),
      data: asMap(v['data']),
      meta: asStringMap(v['meta']),
      namespace: asStringOrNull(v['namespace']),
      zIndex: asInt(v['zIndex']),
      locked: asBool(v['locked']),
      visible: asBool(v['visible'], true),
    );
  }

  static List<Map<String, Object?>> encodeList(Iterable<FlowEdge> edges) =>
      [for (final e in edges) encode(e)];

  static List<FlowEdge> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
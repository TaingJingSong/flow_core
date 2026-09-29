import 'package:meta/meta.dart';

import '../../model/flow_edge.dart';
import '../../model/flow_group.dart';
import '../../model/flow_id.dart';
import '../../model/flow_layer.dart';
import '../../model/flow_node.dart';
import '../../model/flow_page.dart';
import 'edge_codec.dart';
import 'group_codec.dart';
import 'json_utils.dart';
import 'layer_codec.dart';
import 'node_codec.dart';
import 'primitives_codec.dart';

@internal
abstract final class PageCodec {
  static Map<String, Object?> encode(FlowPage p) => {
        'id': p.id.value,
        'name': p.name,
        if (p.bounds != null) 'bounds': RectCodec.encode(p.bounds!),
        if (p.meta.isNotEmpty) 'meta': p.meta,
        'layers': LayerCodec.encodeList(p.layers.values),
        if (p.groups.isNotEmpty) 'groups': GroupCodec.encodeList(p.groups.values),
        if (p.nodes.isNotEmpty) 'nodes': NodeCodec.encodeList(p.nodes.values),
        if (p.edges.isNotEmpty) 'edges': EdgeCodec.encodeList(p.edges.values),
      };

  static FlowPage decode(Object? v) {
    if (v is! Map) {
      throw const FormatException('Page must be a JSON object');
    }

    final layers = <FlowId, FlowLayer>{};
    for (final l in LayerCodec.decodeList(v['layers'])) {
      layers[l.id] = l;
    }

    final groups = <FlowId, FlowGroup>{};
    for (final g in GroupCodec.decodeList(v['groups'])) {
      groups[g.id] = g;
    }

    final nodes = <FlowId, FlowNode>{};
    for (final n in NodeCodec.decodeList(v['nodes'])) {
      nodes[n.id] = n;
    }

    final edges = <FlowId, FlowEdge>{};
    for (final e in EdgeCodec.decodeList(v['edges'])) {
      edges[e.id] = e;
    }

    return FlowPage(
      id: FlowId(asString(v['id'])),
      name: asString(v['name'], 'Page'),
      bounds: RectCodec.decodeOrNull(v['bounds']),
      meta: asStringMap(v['meta']),
      layers: layers,
      groups: groups,
      nodes: nodes,
      edges: edges,
    );
  }

  static List<Map<String, Object?>> encodeList(Iterable<FlowPage> pages) =>
      [for (final p in pages) encode(p)];

  static List<FlowPage> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}
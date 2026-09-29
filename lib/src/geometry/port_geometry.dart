import 'package:meta/meta.dart';

import '../model/flow_node.dart';
import '../model/flow_port.dart';
import 'flow_point.dart';

/// Absolute position of [port] on [node], in node-local coordinates.
///
/// Ignores [FlowNode.rotation] for now; rotation-aware port positions come
/// later when rotation is fully supported by the renderer.
@internal
FlowPoint portPosition(FlowNode node, FlowPort port) {
  final r = node.rect;
  switch (port.side) {
    case FlowPortSide.top:
      return FlowPoint(r.left + r.width * port.position, r.top);
    case FlowPortSide.right:
      return FlowPoint(r.right, r.top + r.height * port.position);
    case FlowPortSide.bottom:
      return FlowPoint(r.left + r.width * port.position, r.bottom);
    case FlowPortSide.left:
      return FlowPoint(r.left, r.top + r.height * port.position);
    case FlowPortSide.center:
      return r.center;
  }
}

/// Absolute position of the named port on [node], or null if not found.
@internal
FlowPoint? portPositionByName(FlowNode node, String? portName) {
  if (portName == null) return null;
  for (final p in node.ports) {
    if (p.name == portName) return portPosition(node, p);
  }
  return null;
}
import 'package:flow_core/flow_core.dart';
import 'package:meta/meta.dart';

import 'port_geometry.dart';
import 'segment_geometry.dart';

/// Returns the polyline that represents [edge] on [page] for hit testing.
///
/// Straight-line by default, with waypoints inserted between source and
/// target anchors. When the routing layer lands (Step 8), this function
/// will delegate to the active router.
@internal
List<FlowPoint> edgePolyline(FlowEdge edge, FlowPage page) {
  final source = page.nodes[edge.sourceNodeId];
  final target = page.nodes[edge.targetNodeId];
  if (source == null || target == null) return const <FlowPoint>[];

  final sourceAnchor = portPositionByName(source, edge.sourcePortName) ??
      source.rect.center;
  final targetAnchor = portPositionByName(target, edge.targetPortName) ??
      target.rect.center;

  if (edge.waypoints.isEmpty) {
    return <FlowPoint>[sourceAnchor, targetAnchor];
  }
  return <FlowPoint>[sourceAnchor, ...edge.waypoints, targetAnchor];
}

/// Bounding box of [edge]'s polyline on [page].
@internal
FlowRect edgeBounds(FlowEdge edge, FlowPage page) {
  final polyline = edgePolyline(edge, page);
  if (polyline.isEmpty) return FlowRect.zero;
  var left = polyline.first.x;
  var right = polyline.first.x;
  var top = polyline.first.y;
  var bottom = polyline.first.y;
  for (final p in polyline) {
    if (p.x < left) left = p.x;
    if (p.x > right) right = p.x;
    if (p.y < top) top = p.y;
    if (p.y > bottom) bottom = p.y;
  }
  final width = right - left;
  final height = bottom - top;
  return FlowRect.fromLTWH(
    width == 0 ? left - 1 : left,
    height == 0 ? top - 1 : top,
    width == 0 ? 2 : width,
    height == 0 ? 2 : height,
  );
}

/// Whether any segment of [edge] intersects [rect].
@internal
bool edgeIntersectsRect(FlowEdge edge, FlowPage page, FlowRect rect) {
  final polyline = edgePolyline(edge, page);
  if (polyline.isEmpty) return false;
  if (polyline.length == 1) return rect.contains(polyline.first);
  for (var i = 0; i < polyline.length - 1; i++) {
    if (segmentIntersectsRect(polyline[i], polyline[i + 1], rect)) return true;
  }
  return false;
}

/// Resolves the anchor point and side for [node] when connecting to it.
///
/// - If [portName] is given and matches a declared port, the port's
///   position and side are returned.
/// - Otherwise the anchor is auto-computed on the boundary of the node
///   nearest to [toward].
FlowAnchor resolveAnchor(
  FlowNode node,
  String? portName, {
  required FlowPoint toward,
}) {
  if (portName != null) {
    for (final p in node.ports) {
      if (p.name == portName) {
        return FlowAnchor(portPosition(node, p), p.side);
      }
    }
  }
  return autoAnchor(node, toward);
}

/// Auto-anchors to the boundary of [node] in the direction of [toward].
FlowAnchor autoAnchor(FlowNode node, FlowPoint toward) {
  final r = node.rect;
  final c = r.center;
  final dx = toward.x - c.x;
  final dy = toward.y - c.y;

  if (dx == 0 && dy == 0) return FlowAnchor(c, FlowPortSide.center);
  if (r.width == 0 || r.height == 0) return FlowAnchor(c, FlowPortSide.center);

  final halfW = r.width / 2;
  final halfH = r.height / 2;
  final tX = dx == 0 ? double.infinity : halfW / dx.abs();
  final tY = dy == 0 ? double.infinity : halfH / dy.abs();
  final t = tX < tY ? tX : tY;

  final position = FlowPoint(c.x + dx * t, c.y + dy * t);
  final FlowPortSide side;
  if (tX <= tY) {
    side = dx >= 0 ? FlowPortSide.right : FlowPortSide.left;
  } else {
    side = dy >= 0 ? FlowPortSide.bottom : FlowPortSide.top;
  }
  return FlowAnchor(position, side);
}
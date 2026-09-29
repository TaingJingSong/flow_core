import 'package:flow_core/flow_core.dart';

/// Computes the routed path for [edge] on [page].
///
/// When [router] is null, the router is chosen by [edge.routing] via
/// [FlowRouterRegistry], or `StraightRouter` if no registry is provided.
FlowPath routeEdge(
  FlowEdge edge,
  FlowPage page, {
  FlowEdgeRouter? router,
  FlowRouterRegistry? registry,
  double portPadding = 20.0,
}) {
  final source = page.nodes[edge.sourceNodeId];
  final target = page.nodes[edge.targetNodeId];
  if (source == null || target == null) return FlowPath.empty;

  final chosen = router ??
      (registry != null
          ? registry.routerFor(edge.routing)
          : const StraightRouter());

  final context = buildRoutingContext(
    edge: edge,
    source: source,
    target: target,
    page: page,
    portPadding: portPadding,
  );

  return chosen.route(context);
}

/// Convenience wrapper that returns only the polyline.
List<FlowPoint> routedPolyline(
  FlowEdge edge,
  FlowPage page, {
  FlowEdgeRouter? router,
  FlowRouterRegistry? registry,
  double portPadding = 20.0,
}) =>
    routeEdge(
      edge,
      page,
      router: router,
      registry: registry,
      portPadding: portPadding,
    ).points;

/// Builds a routing context, resolving anchors and exit sides.
FlowRoutingContext buildRoutingContext({
  required FlowEdge edge,
  required FlowNode source,
  required FlowNode target,
  required FlowPage page,
  double portPadding = 20.0,
}) {
  final sourceAnchorInfo = resolveAnchor(
    source,
    edge.sourcePortName,
    toward: target.rect.center,
  );
  final targetAnchorInfo = resolveAnchor(
    target,
    edge.targetPortName,
    toward: source.rect.center,
  );

  final obstacles = <FlowRect>[];
  for (final n in page.nodes.values) {
    if (n.id == source.id || n.id == target.id) continue;
    if (!n.visible) continue;
    obstacles.add(n.rect);
  }

  return FlowRoutingContext(
    edge: edge,
    source: source,
    target: target,
    sourceAnchor: sourceAnchorInfo.position,
    targetAnchor: targetAnchorInfo.position,
    sourceSide: sourceAnchorInfo.side,
    targetSide: targetAnchorInfo.side,
    obstacles: obstacles,
    portPadding: portPadding,
  );
}
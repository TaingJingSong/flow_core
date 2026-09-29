import 'flow_path.dart';
import 'flow_routing_context.dart';

/// Computes the geometry of an edge.
///
/// Implementations must be pure: same context -> same path. They must not
/// mutate the context or the document.
abstract class FlowEdgeRouter {
  const FlowEdgeRouter();

  /// Stable identifier used by [FlowRouterRegistry] and the `routing`
  /// enum-to-id mapping.
  String get id;

  /// Human-readable name for UI.
  String get name;

  FlowPath route(FlowRoutingContext context);
}
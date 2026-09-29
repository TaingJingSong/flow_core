import '../model/flow_edge.dart';
import 'flow_edge_router.dart';
import 'routers/bezier_router.dart';
import 'routers/orthogonal_router.dart';
import 'routers/straight_router.dart';

/// Registry of edge routers keyed by [FlowEdgeRouter.id].
///
/// The default registry ships with straight, orthogonal, and bezier.
/// Plugins may add more.
class FlowRouterRegistry {
  FlowRouterRegistry({bool withDefaults = true}) {
    if (withDefaults) {
      register(const StraightRouter());
      register(const OrthogonalRouter());
      register(const BezierRouter());
      _fallbackId = 'straight';
    }
  }

  final Map<String, FlowEdgeRouter> _byId = <String, FlowEdgeRouter>{};
  String _fallbackId = 'straight';

  Iterable<FlowEdgeRouter> get routers => _byId.values;

  /// Registers [router]. Overwrites any router with the same id.
  void register(FlowEdgeRouter router) {
    _byId[router.id] = router;
  }

  /// Removes the router with [id]. No-op if not present.
  void unregister(String id) {
    _byId.remove(id);
  }

  /// Sets the router used when an id is unknown.
  void setFallback(String id) {
    if (_byId.containsKey(id)) _fallbackId = id;
  }

  /// Looks up a router by [id], or null if not present.
  FlowEdgeRouter? byId(String id) => _byId[id];

  /// Returns the router for [routing], falling back if not registered.
  FlowEdgeRouter routerFor(FlowEdgeRouting routing) {
    final id = routerIdFor(routing);
    return _byId[id] ?? _byId[_fallbackId] ?? const StraightRouter();
  }

  /// Maps a routing enum to the canonical router id.
  static String routerIdFor(FlowEdgeRouting routing) {
    switch (routing) {
      case FlowEdgeRouting.straight:
        return 'straight';
      case FlowEdgeRouting.orthogonal:
        return 'orthogonal';
      case FlowEdgeRouting.bezier:
        return 'bezier';
      case FlowEdgeRouting.quadratic:
        // No built-in quadratic router yet; bezier is the closest match.
        return 'bezier';
      case FlowEdgeRouting.obstacleAvoiding:
        // Until obstacle avoidance lands, orthogonal is the closest.
        return 'orthogonal';
      case FlowEdgeRouting.custom:
        return 'straight';
    }
  }
}
import 'flow_layout_engine.dart';
import 'layouts/circular_layout.dart';
import 'layouts/grid_layout.dart';
import 'layouts/layered_layout.dart';
import 'layouts/tree_layout.dart';

/// Registry of layout engines keyed by [FlowLayoutEngine.id].
class FlowLayoutRegistry {
  FlowLayoutRegistry({bool withDefaults = true}) {
    if (withDefaults) {
      register(const LayeredLayout());
      register(const TreeLayout());
      register(const GridLayout());
      register(const CircularLayout());
      _fallbackId = 'layered';
    }
  }

  final Map<String, FlowLayoutEngine> _byId = <String, FlowLayoutEngine>{};
  String _fallbackId = 'layered';

  Iterable<FlowLayoutEngine> get engines => _byId.values;

  void register(FlowLayoutEngine engine) => _byId[engine.id] = engine;

  void unregister(String id) => _byId.remove(id);

  void setFallback(String id) {
    if (_byId.containsKey(id)) _fallbackId = id;
  }

  FlowLayoutEngine? byId(String id) => _byId[id];

  FlowLayoutEngine get fallback =>
      _byId[_fallbackId] ?? const LayeredLayout();
}
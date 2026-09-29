import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../geometry/flow_rect.dart';
import '../model/flow_id.dart';

const _mapEq = MapEquality<FlowId, FlowRect>();

/// The output of a layout engine.
@immutable
class FlowLayoutResult {
  FlowLayoutResult(Map<FlowId, FlowRect> rects)
      : rects = Map.unmodifiable(rects);

  /// Final rect for each node id.
  final Map<FlowId, FlowRect> rects;

  /// Bounding box of every rect in the result, or null if empty.
  FlowRect? get bounds {
    if (rects.isEmpty) return null;
    FlowRect? acc;
    for (final r in rects.values) {
      acc = acc == null ? r : acc.union(r);
    }
    return acc;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowLayoutResult && _mapEq.equals(other.rects, rects);

  @override
  int get hashCode => _mapEq.hash(rects);

  @override
  String toString() => 'FlowLayoutResult(${rects.length} nodes)';
}
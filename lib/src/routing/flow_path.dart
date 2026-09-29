import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../geometry/flow_point.dart';
import '../geometry/flow_rect.dart';
import '../geometry/segment_geometry.dart';

const _listEq = ListEquality<FlowPoint>();

/// A single cubic bezier segment: `p1` -> `p2` with controls `c1`, `c2`.
@immutable
class FlowCubic {
  const FlowCubic(this.p1, this.c1, this.c2, this.p2);

  final FlowPoint p1;
  final FlowPoint c1;
  final FlowPoint c2;
  final FlowPoint p2;

  FlowPoint evaluate(double t) {
    final u = 1 - t;
    final b1 = u * u * u;
    final b2 = 3 * u * u * t;
    final b3 = 3 * u * t * t;
    final b4 = t * t * t;
    return FlowPoint(
      b1 * p1.x + b2 * c1.x + b3 * c2.x + b4 * p2.x,
      b1 * p1.y + b2 * c1.y + b3 * c2.y + b4 * p2.y,
    );
  }

  List<FlowPoint> flatten(int subdivisions) {
    if (subdivisions < 1) return <FlowPoint>[p1, p2];
    final out = <FlowPoint>[];
    for (var i = 0; i <= subdivisions; i++) {
      out.add(evaluate(i / subdivisions));
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowCubic &&
          other.p1 == p1 &&
          other.c1 == c1 &&
          other.c2 == c2 &&
          other.p2 == p2;

  @override
  int get hashCode => Object.hash(p1, c1, c2, p2);

  @override
  String toString() => 'FlowCubic($p1, $c1, $c2, $p2)';
}

/// The geometry produced by a router.
///
/// - [points] is a polyline used for hit testing, bounds, and length.
/// - [cubics] is an optional list of curves for exact rendering. When empty,
///   [points] is the shape. When present, renderers should draw the cubics
///   and the polyline is a faithful approximation.
@immutable
class FlowPath {
  const FlowPath({
    required this.points,
    this.cubics = const <FlowCubic>[],
  });

  static const FlowPath empty = FlowPath(points: <FlowPoint>[]);

  final List<FlowPoint> points;
  final List<FlowCubic> cubics;

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  bool get hasCubics => cubics.isNotEmpty;

  /// Axis-aligned bounding box of [points].
  FlowRect get bounds {
    if (points.isEmpty) return FlowRect.zero;
    var left = points.first.x;
    var right = points.first.x;
    var top = points.first.y;
    var bottom = points.first.y;
    for (final p in points) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }
    return FlowRect.fromLTWH(left, top, right - left, bottom - top);
  }

  /// Shortest distance from [p] to this path's polyline.
  double distanceTo(FlowPoint p) => distanceToPolyline(p, points);

  /// Approximate total length of the polyline.
  double get length {
    var sum = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      sum += points[i].distanceTo(points[i + 1]);
    }
    return sum;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowPath &&
          _listEq.equals(other.points, points) &&
          const ListEquality<FlowCubic>().equals(other.cubics, cubics);

  @override
  int get hashCode =>
      Object.hash(_listEq.hash(points), const ListEquality<FlowCubic>().hash(cubics));

  @override
  String toString() =>
      'FlowPath(${points.length} pts, ${cubics.length} cubics)';
}
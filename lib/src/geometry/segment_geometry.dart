import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'flow_point.dart';
import 'flow_rect.dart';

/// Shortest distance from [p] to the segment `[a, b]`.
@internal
double distanceToSegment(FlowPoint p, FlowPoint a, FlowPoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final lenSq = dx * dx + dy * dy;
  if (lenSq == 0) return p.distanceTo(a);
  var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  return p.distanceTo(FlowPoint(a.x + t * dx, a.y + t * dy));
}

/// Shortest distance from [p] to the polyline through [points].
///
/// Returns [double.infinity] for empty polylines, 0 for a single point
/// equal to [p], and the point's distance otherwise.
@internal
double distanceToPolyline(FlowPoint p, List<FlowPoint> points) {
  if (points.isEmpty) return double.infinity;
  if (points.length == 1) return p.distanceTo(points.first);
  var best = double.infinity;
  for (var i = 0; i < points.length - 1; i++) {
    final d = distanceToSegment(p, points[i], points[i + 1]);
    if (d < best) best = d;
  }
  return best;
}

/// Whether the segment `[a, b]` intersects the axis-aligned rectangle [r].
@internal
bool segmentIntersectsRect(FlowPoint a, FlowPoint b, FlowRect r) {
  // Endpoint inside?
  if (r.contains(a) || r.contains(b)) return true;

  // Check intersection with each of the four edges of the rect.
  final tl = r.topLeft;
  final tr = r.topRight;
  final bl = r.bottomLeft;
  final br = r.bottomRight;

  return _segmentsIntersect(a, b, tl, tr) ||
      _segmentsIntersect(a, b, tr, br) ||
      _segmentsIntersect(a, b, br, bl) ||
      _segmentsIntersect(a, b, bl, tl);
}

bool _segmentsIntersect(FlowPoint p1, FlowPoint p2, FlowPoint p3, FlowPoint p4) {
  final d1 = _cross(p3, p4, p1);
  final d2 = _cross(p3, p4, p2);
  final d3 = _cross(p1, p2, p3);
  final d4 = _cross(p1, p2, p4);
  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  if (d1 == 0 && _onSegment(p3, p4, p1)) return true;
  if (d2 == 0 && _onSegment(p3, p4, p2)) return true;
  if (d3 == 0 && _onSegment(p1, p2, p3)) return true;
  if (d4 == 0 && _onSegment(p1, p2, p4)) return true;
  return false;
}

double _cross(FlowPoint a, FlowPoint b, FlowPoint c) =>
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);

bool _onSegment(FlowPoint a, FlowPoint b, FlowPoint p) {
  return math.min(a.x, b.x) <= p.x &&
      p.x <= math.max(a.x, b.x) &&
      math.min(a.y, b.y) <= p.y &&
      p.y <= math.max(a.y, b.y);
}
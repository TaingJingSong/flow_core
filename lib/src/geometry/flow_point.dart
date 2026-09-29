import 'dart:math' as math;
import 'package:meta/meta.dart';

@immutable
class FlowPoint {
  const FlowPoint(this.x, this.y);

  static const FlowPoint zero = FlowPoint(0, 0);

  final double x;
  final double y;

  FlowPoint operator +(FlowPoint other) => FlowPoint(x + other.x, y + other.y);
  FlowPoint operator -(FlowPoint other) => FlowPoint(x - other.x, y - other.y);
  FlowPoint operator *(double scalar) => FlowPoint(x * scalar, y * scalar);
  FlowPoint operator /(double scalar) => FlowPoint(x / scalar, y / scalar);
  FlowPoint operator -() => FlowPoint(-x, -y);

  double distanceTo(FlowPoint other) => math.sqrt(distanceSquaredTo(other));

  double distanceSquaredTo(FlowPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double get magnitude => math.sqrt(x * x + y * y);

  FlowPoint normalized() {
    final m = magnitude;
    return m == 0 ? zero : FlowPoint(x / m, y / m);
  }

  FlowPoint lerp(FlowPoint other, double t) =>
      FlowPoint(x + (other.x - x) * t, y + (other.y - y) * t);

  FlowPoint copyWith({double? x, double? y}) => FlowPoint(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'FlowPoint($x, $y)';
}
import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'flow_point.dart';
import 'flow_size.dart';

/// An immutable axis-aligned rectangle in diagram space.
///
/// Origin is top-left, y grows downward — matches typical canvas
/// conventions in Flutter and SVG.
@immutable
class FlowRect {
  const FlowRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory FlowRect.fromLTWH(double left, double top, double width, double height) =>
      FlowRect(left: left, top: top, width: width, height: height);

  factory FlowRect.fromPoints(FlowPoint a, FlowPoint b) {
    final left = math.min(a.x, b.x);
    final top = math.min(a.y, b.y);
    final right = math.max(a.x, b.x);
    final bottom = math.max(a.y, b.y);
    return FlowRect(left: left, top: top, width: right - left, height: bottom - top);
  }

  static const FlowRect zero = FlowRect(left: 0, top: 0, width: 0, height: 0);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  FlowPoint get topLeft => FlowPoint(left, top);
  FlowPoint get topRight => FlowPoint(right, top);
  FlowPoint get bottomLeft => FlowPoint(left, bottom);
  FlowPoint get bottomRight => FlowPoint(right, bottom);
  FlowPoint get center => FlowPoint(centerX, centerY);

  FlowSize get size => FlowSize(width, height);

  bool get isEmpty => width <= 0 || height <= 0;

  bool contains(FlowPoint point) =>
      point.x >= left && point.x <= right && point.y >= top && point.y <= bottom;

  bool containsRect(FlowRect other) =>
      other.left >= left &&
      other.top >= top &&
      other.right <= right &&
      other.bottom <= bottom;

  bool intersects(FlowRect other) =>
      left < other.right &&
      right > other.left &&
      top < other.bottom &&
      bottom > other.top;

  FlowRect intersect(FlowRect other) {
    final l = math.max(left, other.left);
    final t = math.max(top, other.top);
    final r = math.min(right, other.right);
    final b = math.min(bottom, other.bottom);
    if (r <= l || b <= t) return zero;
    return FlowRect.fromLTWH(l, t, r - l, b - t);
  }

  FlowRect union(FlowRect other) {
    if (isEmpty) return other;
    if (other.isEmpty) return this;
    final l = math.min(left, other.left);
    final t = math.min(top, other.top);
    final r = math.max(right, other.right);
    final b = math.max(bottom, other.bottom);
    return FlowRect.fromLTWH(l, t, r - l, b - t);
  }

  FlowRect inflate(double delta) => FlowRect.fromLTWH(
        left - delta,
        top - delta,
        width + delta * 2,
        height + delta * 2,
      );

  FlowRect translate(double dx, double dy) =>
      FlowRect.fromLTWH(left + dx, top + dy, width, height);

  FlowRect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) =>
      FlowRect(
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowRect &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'FlowRect($left, $top, $width x $height)';
}
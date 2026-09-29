import 'dart:math' as math;
import 'package:meta/meta.dart';

/// An immutable 2D size.
@immutable
class FlowSize {
  const FlowSize(this.width, this.height);

  static const FlowSize zero = FlowSize(0, 0);

  final double width;
  final double height;

  double get area => width * height;
  bool get isEmpty => width <= 0 || height <= 0;

  FlowSize operator *(double scalar) => FlowSize(width * scalar, height * scalar);

  FlowSize copyWith({double? width, double? height}) =>
      FlowSize(width ?? this.width, height ?? this.height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'FlowSize($width x $height)';

  /// Convenience for diagonal length.
  double get diagonal => math.sqrt(width * width + height * height);
}
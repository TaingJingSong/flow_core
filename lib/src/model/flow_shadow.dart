import 'package:meta/meta.dart';
import '../geometry/flow_point.dart';
import 'flow_color.dart';

/// A drop shadow applied to nodes or groups.
@immutable
class FlowShadow {
  const FlowShadow({
    this.color = const FlowColor(0x33000000),
    this.offset = FlowPoint.zero,
    this.blurRadius = 0,
    this.spreadRadius = 0,
  });

  final FlowColor color;
  final FlowPoint offset;
  final double blurRadius;
  final double spreadRadius;

  FlowShadow copyWith({
    FlowColor? color,
    FlowPoint? offset,
    double? blurRadius,
    double? spreadRadius,
  }) =>
      FlowShadow(
        color: color ?? this.color,
        offset: offset ?? this.offset,
        blurRadius: blurRadius ?? this.blurRadius,
        spreadRadius: spreadRadius ?? this.spreadRadius,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowShadow &&
          other.color == color &&
          other.offset == offset &&
          other.blurRadius == blurRadius &&
          other.spreadRadius == spreadRadius;

  @override
  int get hashCode => Object.hash(color, offset, blurRadius, spreadRadius);

  @override
  String toString() =>
      'FlowShadow($color, $offset, blur: $blurRadius, spread: $spreadRadius)';
}
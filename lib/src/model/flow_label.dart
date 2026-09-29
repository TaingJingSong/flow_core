import 'package:meta/meta.dart';
import '../geometry/flow_point.dart';
import 'flow_text_style.dart';

/// Where the label sits relative to its owner.
enum FlowLabelPosition {
  center,
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  start,
  end,
  custom,
}

enum FlowLabelAlignment { left, center, right, justify }

/// Text attached to a node, edge, group, or standalone.
@immutable
class FlowLabel {
  const FlowLabel({
    this.text = '',
    this.style,
    this.position = FlowLabelPosition.center,
    this.alignment = FlowLabelAlignment.center,
    this.offset = FlowPoint.zero,
    this.maxWidth,
    this.rotation = 0.0,
  });

  final String text;
  final FlowTextStyle? style;
  final FlowLabelPosition position;
  final FlowLabelAlignment alignment;
  final FlowPoint offset;
  final double? maxWidth;

  /// Rotation in radians around the label's anchor.
  final double rotation;

  bool get isEmpty => text.isEmpty;

  FlowLabel copyWith({
    String? text,
    Object? style = _unset,
    FlowLabelPosition? position,
    FlowLabelAlignment? alignment,
    FlowPoint? offset,
    Object? maxWidth = _unset,
    double? rotation,
  }) =>
      FlowLabel(
        text: text ?? this.text,
        style: style == _unset ? this.style : style as FlowTextStyle?,
        position: position ?? this.position,
        alignment: alignment ?? this.alignment,
        offset: offset ?? this.offset,
        maxWidth: maxWidth == _unset ? this.maxWidth : maxWidth as double?,
        rotation: rotation ?? this.rotation,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowLabel &&
          other.text == text &&
          other.style == style &&
          other.position == position &&
          other.alignment == alignment &&
          other.offset == offset &&
          other.maxWidth == maxWidth &&
          other.rotation == rotation;

  @override
  int get hashCode => Object.hash(
        text,
        style,
        position,
        alignment,
        offset,
        maxWidth,
        rotation,
      );

  @override
  String toString() => 'FlowLabel("$text")';
}

const Object _unset = Object();
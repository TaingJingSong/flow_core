import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'flow_color.dart';
import 'flow_shadow.dart';
import 'flow_text_style.dart';

const _listEq = ListEquality<double>();
const Object _unset = Object();

/// Visual style applied to nodes, edges, groups, and labels.
///
/// Any field may be null, meaning "inherit from parent" or "renderer default".
@immutable
class FlowStyle {
  const FlowStyle({
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.strokeDashPattern,
    this.cornerRadius = 0.0,
    this.opacity = 1.0,
    this.shadow,
    this.textStyle,
  });

  final FlowColor? fillColor;
  final FlowColor? strokeColor;
  final double strokeWidth;

  /// Dash pattern in logical pixels, e.g. `[4, 2]` = 4 on, 2 off.
  final List<double>? strokeDashPattern;

  final double cornerRadius;
  final double opacity;
  final FlowShadow? shadow;

  /// Default text style for labels that don't specify their own.
  final FlowTextStyle? textStyle;

  FlowStyle copyWith({
    Object? fillColor = _unset,
    Object? strokeColor = _unset,
    double? strokeWidth,
    Object? strokeDashPattern = _unset,
    double? cornerRadius,
    double? opacity,
    Object? shadow = _unset,
    Object? textStyle = _unset,
  }) =>
      FlowStyle(
        fillColor: fillColor == _unset ? this.fillColor : fillColor as FlowColor?,
        strokeColor:
            strokeColor == _unset ? this.strokeColor : strokeColor as FlowColor?,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        strokeDashPattern: strokeDashPattern == _unset
            ? this.strokeDashPattern
            : strokeDashPattern as List<double>?,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        opacity: opacity ?? this.opacity,
        shadow: shadow == _unset ? this.shadow : shadow as FlowShadow?,
        textStyle:
            textStyle == _unset ? this.textStyle : textStyle as FlowTextStyle?,
      );

  FlowStyle merge(FlowStyle? other) {
    if (other == null) return this;
    return FlowStyle(
      fillColor: other.fillColor ?? fillColor,
      strokeColor: other.strokeColor ?? strokeColor,
      strokeWidth: other.strokeWidth,
      strokeDashPattern: other.strokeDashPattern ?? strokeDashPattern,
      cornerRadius: other.cornerRadius,
      opacity: other.opacity,
      shadow: other.shadow ?? shadow,
      textStyle: other.textStyle ?? textStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowStyle &&
          other.fillColor == fillColor &&
          other.strokeColor == strokeColor &&
          other.strokeWidth == strokeWidth &&
          _listEq.equals(other.strokeDashPattern, strokeDashPattern) &&
          other.cornerRadius == cornerRadius &&
          other.opacity == opacity &&
          other.shadow == shadow &&
          other.textStyle == textStyle;

  @override
  int get hashCode => Object.hash(
        fillColor,
        strokeColor,
        strokeWidth,
        strokeDashPattern == null ? null : _listEq.hash(strokeDashPattern),
        cornerRadius,
        opacity,
        shadow,
        textStyle,
      );

  static const FlowStyle defaults = FlowStyle();
}
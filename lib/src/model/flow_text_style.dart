import 'package:meta/meta.dart';
import 'flow_color.dart';

/// Font weight as an integer from 100 to 900. Mirrors CSS / Flutter.
@immutable
class FlowFontWeight {
  const FlowFontWeight(this.value);

  final int value;

  static const FlowFontWeight w100 = FlowFontWeight(100);
  static const FlowFontWeight w200 = FlowFontWeight(200);
  static const FlowFontWeight w300 = FlowFontWeight(300);
  static const FlowFontWeight w400 = FlowFontWeight(400);
  static const FlowFontWeight w500 = FlowFontWeight(500);
  static const FlowFontWeight w600 = FlowFontWeight(600);
  static const FlowFontWeight w700 = FlowFontWeight(700);
  static const FlowFontWeight w800 = FlowFontWeight(800);
  static const FlowFontWeight w900 = FlowFontWeight(900);

  static const FlowFontWeight normal = w400;
  static const FlowFontWeight bold = w700;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowFontWeight && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FlowFontWeight($value)';
}

enum FlowFontStyle { normal, italic }

enum FlowTextDecoration { none, underline, overline, lineThrough }

/// Styling for text content inside labels.
@immutable
class FlowTextStyle {
  const FlowTextStyle({
    this.fontFamily,
    this.fontSize = 14,
    this.fontWeight = FlowFontWeight.normal,
    this.fontStyle = FlowFontStyle.normal,
    this.color = FlowColor.black,
    this.letterSpacing,
    this.lineHeight,
    this.decoration = FlowTextDecoration.none,
  });

  final String? fontFamily;
  final double fontSize;
  final FlowFontWeight fontWeight;
  final FlowFontStyle fontStyle;
  final FlowColor color;
  final double? letterSpacing;

  /// Multiplier of `fontSize`. Null means renderer default.
  final double? lineHeight;

  final FlowTextDecoration decoration;

  FlowTextStyle copyWith({
    Object? fontFamily = _unset,
    double? fontSize,
    FlowFontWeight? fontWeight,
    FlowFontStyle? fontStyle,
    FlowColor? color,
    Object? letterSpacing = _unset,
    Object? lineHeight = _unset,
    FlowTextDecoration? decoration,
  }) =>
      FlowTextStyle(
        fontFamily: fontFamily == _unset ? this.fontFamily : fontFamily as String?,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        fontStyle: fontStyle ?? this.fontStyle,
        color: color ?? this.color,
        letterSpacing:
            letterSpacing == _unset ? this.letterSpacing : letterSpacing as double?,
        lineHeight: lineHeight == _unset ? this.lineHeight : lineHeight as double?,
        decoration: decoration ?? this.decoration,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowTextStyle &&
          other.fontFamily == fontFamily &&
          other.fontSize == fontSize &&
          other.fontWeight == fontWeight &&
          other.fontStyle == fontStyle &&
          other.color == color &&
          other.letterSpacing == letterSpacing &&
          other.lineHeight == lineHeight &&
          other.decoration == decoration;

  @override
  int get hashCode => Object.hash(
        fontFamily,
        fontSize,
        fontWeight,
        fontStyle,
        color,
        letterSpacing,
        lineHeight,
        decoration,
      );

  static const FlowTextStyle defaults = FlowTextStyle();
}

/// Sentinel for `copyWith` so callers can explicitly set fields to null.
const Object _unset = Object();
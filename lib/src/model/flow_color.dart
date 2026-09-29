import 'package:meta/meta.dart';

/// An immutable, platform-independent 32-bit ARGB color.
///
/// Convert it to a `dart:ui` color with `Color(flowColor.value)`.
@immutable
class FlowColor {
  /// Creates a color from a packed 32-bit ARGB [value].
  const FlowColor(this.value);

  /// Creates a color from alpha, red, green, and blue components.
  ///
  /// Each component is masked to 8 bits.
  const FlowColor.fromARGB(int a, int r, int g, int b)
      : value = ((a & 0xFF) << 24) |
            ((r & 0xFF) << 16) |
            ((g & 0xFF) << 8) |
            (b & 0xFF);

  /// The packed 32-bit ARGB value.
  final int value;

  /// The alpha component, from 0 to 255.
  int get alpha => (value >> 24) & 0xFF;

  /// The red component, from 0 to 255.
  int get red => (value >> 16) & 0xFF;

  /// The green component, from 0 to 255.
  int get green => (value >> 8) & 0xFF;

  /// The blue component, from 0 to 255.
  int get blue => value & 0xFF;

  /// The alpha component normalized to the range 0.0 to 1.0.
  double get opacity => alpha / 255.0;

  /// Returns a color with the given [alpha] component.
  FlowColor withAlpha(int alpha) =>
      FlowColor.fromARGB(alpha, red, green, blue);

  /// Returns a color with [opacity] converted to an 8-bit alpha component.
  ///
  /// Values outside 0.0 to 1.0 are clamped.
  FlowColor withOpacity(double opacity) =>
      withAlpha((opacity * 255).round().clamp(0, 255));

  static const FlowColor transparent = FlowColor(0x00000000);
  static const FlowColor black = FlowColor(0xFF000000);
  static const FlowColor white = FlowColor(0xFFFFFFFF);
  static const FlowColor redColor = FlowColor(0xFFFF0000);
  static const FlowColor greenColor = FlowColor(0xFF00FF00);
  static const FlowColor blueColor = FlowColor(0xFF0000FF);
  static const FlowColor grey = FlowColor(0xFF808080);
  static const FlowColor lightGrey = FlowColor(0xFFE0E0E0);
  static const FlowColor darkGrey = FlowColor(0xFF404040);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FlowColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() =>
      'FlowColor(0x${value.toRadixString(16).padLeft(8, '0')})';
}
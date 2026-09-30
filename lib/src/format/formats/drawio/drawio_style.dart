import 'dart:math' as math;

import 'package:flow_core/flow_core.dart';

/// Parses and emits draw.io's `key=value;key=value` style DSL.
///
/// The DSL is intentionally loose: bare keywords (like `ellipse;`), key-value
/// pairs, and missing trailing semicolons are all tolerated.
abstract final class DrawioStyle {
  /// Parses [styleString] into a [FlowStyle] for a node.
  static FlowStyle parseNodeStyle(String? styleString) {
    if (styleString == null || styleString.isEmpty) {
      return FlowStyle.defaults;
    }
    final parts = _split(styleString);

    FlowColor? fill;
    FlowColor? stroke;
    double strokeWidth = 1.0;
    List<double>? dashPattern;
    double opacity = 1.0;
    double cornerRadius = 0;
    FlowColor? fontColor;
    double? fontSize;
    int fontWeight = 400;
    bool italic = false;

    for (final entry in parts) {
      final eq = entry.indexOf('=');
      final key = eq < 0 ? entry : entry.substring(0, eq);
      final value = eq < 0 ? '' : entry.substring(eq + 1);

      switch (key) {
        case 'rounded':
          if (value == '1') cornerRadius = 8.0;
          break;
        case 'fillColor':
          fill = _parseColor(value);
          break;
        case 'strokeColor':
          stroke = _parseColor(value);
          break;
        case 'strokeWidth':
          strokeWidth = double.tryParse(value) ?? 1.0;
          break;
        case 'dashed':
          if (value == '1') dashPattern = const [4, 2];
          break;
        case 'dashPattern':
          dashPattern = _parseDashPattern(value);
          break;
        case 'opacity':
          opacity = (double.tryParse(value) ?? 100) / 100.0;
          break;
        case 'fontColor':
          fontColor = _parseColor(value);
          break;
        case 'fontSize':
          fontSize = double.tryParse(value);
          break;
        case 'fontStyle':
          final bits = int.tryParse(value) ?? 0;
          if (bits & 1 != 0) fontWeight = 700;
          if (bits & 2 != 0) italic = true;
          break;
      }
    }

    return FlowStyle(
      fillColor: fill,
      strokeColor: stroke,
      strokeWidth: strokeWidth,
      strokeDashPattern: dashPattern,
      cornerRadius: cornerRadius,
      opacity: opacity,
      textStyle: (fontColor != null || fontSize != null || italic ||
              fontWeight != 400)
          ? FlowTextStyle(
              color: fontColor ?? const FlowColor(0xFF000000),
              fontSize: fontSize ?? 14,
              fontWeight: FlowFontWeight(fontWeight),
              fontStyle:
                  italic ? FlowFontStyle.italic : FlowFontStyle.normal,
            )
          : null,
    );
  }

  /// Parses [styleString] into the semantic shape type.
  static String parseShape(String? styleString) {
    if (styleString == null || styleString.isEmpty) return 'rectangle';

    final parts = _split(styleString);
    String? explicitShape;
    bool rounded = false;
    bool ellipse = false;
    bool rhombus = false;
    bool hexagon = false;
    bool cylinder = false;
    bool actor = false;
    bool note = false;
    bool triangle = false;
    bool parallelogram = false;
    bool group = false;
    bool text = false;

    for (final entry in parts) {
      final eq = entry.indexOf('=');
      final key = eq < 0 ? entry : entry.substring(0, eq);
      final value = eq < 0 ? '' : entry.substring(eq + 1);

      if (eq < 0) {
        switch (key) {
          case 'ellipse':
            ellipse = true;
            break;
          case 'rhombus':
            rhombus = true;
            break;
          case 'hexagon':
            hexagon = true;
            break;
          case 'cylinder':
          case 'cylinder3':
            cylinder = true;
            break;
          case 'actor':
            actor = true;
            break;
          case 'note':
            note = true;
            break;
          case 'triangle':
            triangle = true;
            break;
          case 'parallelogram':
            parallelogram = true;
            break;
          case 'group':
            group = true;
            break;
          case 'text':
            text = true;
            break;
        }
      } else if (key == 'shape') {
        explicitShape = value;
      } else if (key == 'rounded' && value == '1') {
        rounded = true;
      }
    }

    if (group) return 'group';
    if (text) return 'text';

    final s = explicitShape;
    if (s != null) {
      switch (s) {
        case 'ellipse':
        case 'circle':
          return 'circle';
        case 'rhombus':
          return 'diamond';
        case 'hexagon':
          return 'hexagon';
        case 'cylinder':
        case 'cylinder3':
          return 'cylinder';
        case 'actor':
        case 'umlActor':
          return 'actor';
        case 'note':
          return 'note';
        case 'parallelogram':
          return 'parallelogram';
        case 'triangle':
          return 'triangle';
        case 'cloud':
          return 'cloud';
        case 'document':
          return 'document';
        case 'process':
          return 'rounded';
        case 'swimlane':
          return 'swimlane';
      }
      return s;
    }

    if (ellipse) return 'circle';
    if (rhombus) return 'diamond';
    if (hexagon) return 'hexagon';
    if (cylinder) return 'cylinder';
    if (actor) return 'actor';
    if (note) return 'note';
    if (triangle) return 'triangle';
    if (parallelogram) return 'parallelogram';
    if (rounded) return 'rounded';
    return 'rectangle';
  }

  /// Parses edge-only fields.
  static DrawioEdgeStyle parseEdgeStyle(String? styleString) {
    if (styleString == null || styleString.isEmpty) {
      return const DrawioEdgeStyle();
    }
    final parts = _split(styleString);

    bool dashed = false;
    bool thick = false;
    var startArrow = FlowArrowHead.none;
    var endArrow = FlowArrowHead.filledArrow;

    for (final entry in parts) {
      final eq = entry.indexOf('=');
      final key = eq < 0 ? entry : entry.substring(0, eq);
      final value = eq < 0 ? '' : entry.substring(eq + 1);

      switch (key) {
        case 'dashed':
          if (value == '1') dashed = true;
          break;
        case 'strokeWidth':
          final w = double.tryParse(value);
          if (w != null && w >= 2) thick = true;
          break;
        case 'startArrow':
          startArrow = _parseArrow(value);
          break;
        case 'endArrow':
          endArrow = _parseArrow(value);
          break;
      }
    }
    return DrawioEdgeStyle(
      dashed: dashed,
      thick: thick,
      startArrow: startArrow,
      endArrow: endArrow,
    );
  }

  /// Emits a [FlowStyle] as a draw.io style string.
  ///
  /// When [preserve] is provided (typically from `data['drawio']['style']`),
  /// it is returned verbatim for lossless round-trips.
  static String emitNodeStyle(
    FlowStyle style, {
    required String shape,
    String? preserve,
  }) {
    if (preserve != null && preserve.isNotEmpty) return preserve;

    final parts = <String>[];

    switch (shape) {
      case 'circle':
        parts.add('ellipse');
        break;
      case 'diamond':
        parts.add('rhombus');
        break;
      case 'hexagon':
        parts.add('shape=hexagon');
        break;
      case 'cylinder':
        parts.add('shape=cylinder3');
        break;
      case 'actor':
        parts.add('shape=umlActor');
        break;
      case 'note':
        parts.add('shape=note');
        break;
      case 'parallelogram':
        parts.add('shape=parallelogram');
        break;
      case 'triangle':
        parts.add('shape=triangle');
        break;
      case 'cloud':
        parts.add('shape=cloud');
        break;
      case 'document':
        parts.add('shape=document');
        break;
      case 'rounded':
        parts.add('rounded=1');
        break;
      case 'group':
        parts.add('group');
        break;
      case 'text':
        parts.add('text');
        break;
    }

    parts.add('whiteSpace=wrap');
    parts.add('html=1');

    if (style.fillColor != null) {
      parts.add('fillColor=${_emitColor(style.fillColor!)}');
    }
    if (style.strokeColor != null) {
      parts.add('strokeColor=${_emitColor(style.strokeColor!)}');
    }
    if (style.strokeWidth != 1.0) {
      parts.add('strokeWidth=${style.strokeWidth}');
    }
    if ((style.cornerRadius ?? 0.0) > 0 && shape == 'rectangle') {
      parts.add('rounded=1');
    }
    if (style.strokeDashPattern != null) {
      parts.add('dashed=1');
      parts.add('dashPattern=${style.strokeDashPattern!.join(' ')}');
    }
    if (style.opacity != 1.0) {
      parts.add('opacity=${((style.opacity ?? 0.0) * 100).round()}');
    }
    final ts = style.textStyle;
    if (ts != null) {
      if (ts.color != const FlowColor(0xFF000000)) {
        parts.add('fontColor=${_emitColor(ts.color)}');
      }
      if (ts.fontSize != 14) {
        parts.add('fontSize=${ts.fontSize}');
      }
      var bits = 0;
      if (ts.fontWeight.value >= 700) bits |= 1;
      if (ts.fontStyle == FlowFontStyle.italic) bits |= 2;
      if (bits != 0) parts.add('fontStyle=$bits');
    }

    return parts.join(';');
  }

  /// Emits an edge style string.
  static String emitEdgeStyle({
    required bool dashed,
    required bool thick,
    required FlowArrowHead startArrow,
    required FlowArrowHead endArrow,
    String? preserve,
  }) {
    if (preserve != null && preserve.isNotEmpty) return preserve;

    final parts = <String>[
      'edgeStyle=orthogonalEdgeStyle',
      'rounded=0',
      'html=1',
    ];
    if (dashed) parts.add('dashed=1');
    if (thick) parts.add('strokeWidth=3');
    parts.add('startArrow=${_emitArrow(startArrow)}');
    parts.add('endArrow=${_emitArrow(endArrow)}');
    return parts.join(';');
  }

  // ---------------------------------------------------------------------------

  static List<String> _split(String s) =>
      s.split(';').where((e) => e.isNotEmpty).toList();

  static FlowColor? _parseColor(String value) {
    if (value.isEmpty || value == 'none') return null;
    var s = value.startsWith('#') ? value.substring(1) : value;
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final parsed = int.tryParse(s, radix: 16);
    return parsed == null ? null : FlowColor(parsed);
  }

  static String _emitColor(FlowColor c) {
    final hex = c.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    // draw.io drops alpha when it's FF.
    return '#${hex.substring(2)}';
  }

  static List<double>? _parseDashPattern(String value) {
    final parts = value.split(RegExp(r'\s+'));
    final out = <double>[];
    for (final p in parts) {
      final d = double.tryParse(p);
      if (d != null) out.add(d);
    }
    return out.isEmpty ? null : out;
  }

  static FlowArrowHead _parseArrow(String value) {
    switch (value) {
      case 'none':
        return FlowArrowHead.none;
      case 'classic':
      case 'block':
        return FlowArrowHead.filledArrow;
      case 'open':
      case 'openThin':
        return FlowArrowHead.arrow;
      case 'oval':
        return FlowArrowHead.circle;
      case 'diamond':
        return FlowArrowHead.filledDiamond;
      case 'diamondThin':
        return FlowArrowHead.diamond;
      case 'box':
        return FlowArrowHead.filledSquare;
      case 'cross':
        return FlowArrowHead.cross;
      case 'bar':
        return FlowArrowHead.bar;
    }
    return FlowArrowHead.filledArrow;
  }

  static String _emitArrow(FlowArrowHead head) {
    switch (head) {
      case FlowArrowHead.none:
        return 'none';
      case FlowArrowHead.arrow:
        return 'open';
      case FlowArrowHead.filledArrow:
        return 'classic';
      case FlowArrowHead.hollowArrow:
        return 'block';
      case FlowArrowHead.diamond:
        return 'diamondThin';
      case FlowArrowHead.filledDiamond:
        return 'diamond';
      case FlowArrowHead.circle:
      case FlowArrowHead.filledCircle:
        return 'oval';
      case FlowArrowHead.square:
      case FlowArrowHead.filledSquare:
        return 'box';
      case FlowArrowHead.cross:
        return 'cross';
      case FlowArrowHead.bar:
        return 'bar';
    }
  }
}

/// Parsed edge-only style.
class DrawioEdgeStyle {
  const DrawioEdgeStyle({
    this.dashed = false,
    this.thick = false,
    this.startArrow = FlowArrowHead.none,
    this.endArrow = FlowArrowHead.filledArrow,
  });

  final bool dashed;
  final bool thick;
  final FlowArrowHead startArrow;
  final FlowArrowHead endArrow;
}

// Keep math import so we can add clamping later without churn.
// ignore: unused_element
final _ = math.pi;
import 'package:meta/meta.dart';

import '../../geometry/geometry.dart';
import '../../model/flow_color.dart';
import '../../model/flow_shadow.dart';
import 'json_utils.dart';

@internal
abstract final class ColorCodec {
  static String encode(FlowColor color) {
    final hex =
        color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#$hex';
  }

  static FlowColor decode(Object? value,
      {FlowColor fallback = FlowColor.black}) {
    if (value is! String) return fallback;
    var s = value.startsWith('#') ? value.substring(1) : value;
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return fallback;
    final parsed = int.tryParse(s, radix: 16);
    return parsed == null ? fallback : FlowColor(parsed);
  }

  static FlowColor? decodeOrNull(Object? value) =>
      value == null ? null : decode(value);
}

@internal
abstract final class PointCodec {
  static Map<String, Object?> encode(FlowPoint p) => {'x': p.x, 'y': p.y};

  static FlowPoint decode(Object? v) {
    if (v is! Map) return FlowPoint.zero;
    return FlowPoint(asDouble(v['x']), asDouble(v['y']));
  }

  static List<Map<String, Object?>> encodeList(List<FlowPoint> points) =>
      [for (final p in points) encode(p)];

  static List<FlowPoint> decodeList(Object? v) =>
      [for (final item in asList(v)) decode(item)];
}

@internal
abstract final class SizeCodec {
  static Map<String, Object?> encode(FlowSize s) =>
      {'width': s.width, 'height': s.height};

  static FlowSize decode(Object? v) {
    if (v is! Map) return FlowSize.zero;
    return FlowSize(asDouble(v['width']), asDouble(v['height']));
  }
}

@internal
abstract final class RectCodec {
  static Map<String, Object?> encode(FlowRect r) => {
        'left': r.left,
        'top': r.top,
        'width': r.width,
        'height': r.height,
      };

  static FlowRect decode(Object? v) {
    if (v is! Map) return FlowRect.zero;
    return FlowRect(
      left: asDouble(v['left']),
      top: asDouble(v['top']),
      width: asDouble(v['width']),
      height: asDouble(v['height']),
    );
  }

  static FlowRect? decodeOrNull(Object? v) => v == null ? null : decode(v);
}

@internal
abstract final class ShadowCodec {
  static Map<String, Object?> encode(FlowShadow s) => {
        'color': ColorCodec.encode(s.color),
        'offset': PointCodec.encode(s.offset),
        'blurRadius': s.blurRadius,
        'spreadRadius': s.spreadRadius,
      };

  static FlowShadow decode(Object? v) {
    if (v is! Map) return const FlowShadow();
    return FlowShadow(
      color: ColorCodec.decode(v['color']),
      offset: PointCodec.decode(v['offset']),
      blurRadius: asDouble(v['blurRadius']),
      spreadRadius: asDouble(v['spreadRadius']),
    );
  }

  static FlowShadow? decodeOrNull(Object? v) => v == null ? null : decode(v);
}
import 'package:meta/meta.dart';

import '../../model/flow_style.dart';
import '../../model/flow_text_style.dart';
import 'json_utils.dart';
import 'primitives_codec.dart';

@internal
abstract final class TextStyleCodec {
  static Map<String, Object?> encode(FlowTextStyle s) => {
        if (s.fontFamily != null) 'fontFamily': s.fontFamily,
        'fontSize': s.fontSize,
        'fontWeight': s.fontWeight.value,
        'fontStyle': s.fontStyle.name,
        'color': ColorCodec.encode(s.color),
        if (s.letterSpacing != null) 'letterSpacing': s.letterSpacing,
        if (s.lineHeight != null) 'lineHeight': s.lineHeight,
        'decoration': s.decoration.name,
      };

  static FlowTextStyle decode(Object? v) {
    if (v is! Map) return FlowTextStyle.defaults;
    return FlowTextStyle(
      fontFamily: asStringOrNull(v['fontFamily']),
      fontSize: asDouble(v['fontSize'], 14),
      fontWeight: FlowFontWeight(asInt(v['fontWeight'], 400)),
      fontStyle: asEnum(FlowFontStyle.values, v['fontStyle'], FlowFontStyle.normal),
      color: ColorCodec.decode(v['color']),
      letterSpacing:
          v['letterSpacing'] == null ? null : asDouble(v['letterSpacing']),
      lineHeight: v['lineHeight'] == null ? null : asDouble(v['lineHeight']),
      decoration: asEnum(
        FlowTextDecoration.values, v['decoration'], FlowTextDecoration.none),
    );
  }

  static FlowTextStyle? decodeOrNull(Object? v) =>
      v == null ? null : decode(v);
}

@internal
abstract final class StyleCodec {
  static Map<String, Object?> encode(FlowStyle s) => {
        if (s.fillColor != null) 'fillColor': ColorCodec.encode(s.fillColor!),
        if (s.strokeColor != null)
          'strokeColor': ColorCodec.encode(s.strokeColor!),
        'strokeWidth': s.strokeWidth,
        if (s.strokeDashPattern != null)
          'strokeDashPattern': s.strokeDashPattern,
        'cornerRadius': s.cornerRadius,
        'opacity': s.opacity,
        if (s.shadow != null) 'shadow': ShadowCodec.encode(s.shadow!),
        if (s.textStyle != null)
          'textStyle': TextStyleCodec.encode(s.textStyle!),
      };

  static FlowStyle decode(Object? v) {
    if (v is! Map) return FlowStyle.defaults;
    return FlowStyle(
      fillColor: ColorCodec.decodeOrNull(v['fillColor']),
      strokeColor: ColorCodec.decodeOrNull(v['strokeColor']),
      strokeWidth: asDouble(v['strokeWidth'], 1.0),
      strokeDashPattern: asDoubleListOrNull(v['strokeDashPattern']),
      cornerRadius: asDouble(v['cornerRadius'], 0.0),
      opacity: asDouble(v['opacity'], 1.0),
      shadow: ShadowCodec.decodeOrNull(v['shadow']),
      textStyle: TextStyleCodec.decodeOrNull(v['textStyle']),
    );
  }
}
import 'package:meta/meta.dart';

import '../../model/flow_label.dart';
import 'json_utils.dart';
import 'primitives_codec.dart';
import 'style_codec.dart';

@internal
abstract final class LabelCodec {
  static Map<String, Object?> encode(FlowLabel l) => {
        'text': l.text,
        if (l.style != null) 'style': TextStyleCodec.encode(l.style!),
        'position': l.position.name,
        'alignment': l.alignment.name,
        'offset': PointCodec.encode(l.offset),
        if (l.maxWidth != null) 'maxWidth': l.maxWidth,
        'rotation': l.rotation,
      };

  static FlowLabel decode(Object? v) {
    if (v is! Map) return const FlowLabel();
    return FlowLabel(
      text: asString(v['text']),
      style: TextStyleCodec.decodeOrNull(v['style']),
      position: asEnum(
        FlowLabelPosition.values, v['position'], FlowLabelPosition.center),
      alignment: asEnum(
        FlowLabelAlignment.values, v['alignment'], FlowLabelAlignment.center),
      offset: PointCodec.decode(v['offset']),
      maxWidth: v['maxWidth'] == null ? null : asDouble(v['maxWidth']),
      rotation: asDouble(v['rotation']),
    );
  }

  static FlowLabel? decodeOrNull(Object? v) => v == null ? null : decode(v);
}
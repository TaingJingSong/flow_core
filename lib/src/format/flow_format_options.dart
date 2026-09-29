import 'package:meta/meta.dart';

/// Free-form options passed to [FlowFormat.parse] and [FlowFormat.emit].
@immutable
class FlowFormatOptions {
  const FlowFormatOptions({this.values = const <String, Object?>{}});

  static const FlowFormatOptions none = FlowFormatOptions();

  final Map<String, Object?> values;

  Object? operator [](String key) => values[key];

  FlowFormatOptions merge(FlowFormatOptions? other) {
    if (other == null) return this;
    return FlowFormatOptions(values: {...values, ...other.values});
  }
}
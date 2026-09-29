import 'package:meta/meta.dart';

@internal
double asDouble(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

@internal
int asInt(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

@internal
String asString(Object? v, [String fallback = '']) => v is String ? v : fallback;

@internal
String? asStringOrNull(Object? v) => v is String ? v : null;

@internal
bool asBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

@internal
List<Object?> asList(Object? v) => v is List ? v : const <Object?>[];

@internal
Map<String, Object?> asMap(Object? v) {
  if (v is! Map) return const <String, Object?>{};
  final out = <String, Object?>{};
  v.forEach((k, value) => out[k.toString()] = value);
  return out;
}

@internal
Map<String, String> asStringMap(Object? v) {
  if (v is! Map) return const <String, String>{};
  final out = <String, String>{};
  v.forEach((k, value) {
    if (value is String) out[k.toString()] = value;
  });
  return out;
}

@internal
List<String> asStringList(Object? v) =>
    v is List ? v.whereType<String>().toList() : const <String>[];

@internal
Set<String> asStringSet(Object? v) =>
    v is List ? v.whereType<String>().toSet() : const <String>{};

@internal
List<double>? asDoubleListOrNull(Object? v) {
  if (v is! List) return null;
  return v.whereType<num>().map((n) => n.toDouble()).toList();
}

@internal
T asEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

@internal
DateTime? asDateTime(Object? v) => v is String ? DateTime.tryParse(v) : null;
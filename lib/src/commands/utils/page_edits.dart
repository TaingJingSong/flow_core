import 'package:meta/meta.dart';

import '../../model/flow_document.dart';
import '../../model/flow_page.dart';

/// Returns a new [FlowDocument] with [page] replacing the page whose id
/// matches `page.id`. If no matching page exists, returns [document]
/// unchanged.
@internal
FlowDocument replacePage(FlowDocument document, FlowPage page) {
  final pages = [
    for (final p in document.pages) p.id == page.id ? page : p,
  ];
  return document.copyWith(pages: pages);
}

/// Inserts [entry] into [map] at [index], rebuilding the map so that
/// Dart's insertion-order guarantee is preserved.
@internal
Map<K, V> insertAt<K, V>(Map<K, V> map, int index, K key, V value) {
  final entries = map.entries.toList();
  final i = index.clamp(0, entries.length);
  entries.insert(i, MapEntry<K, V>(key, value));
  return {for (final e in entries) e.key: e.value};
}

/// Returns [index] of [key] in [map]'s insertion order, or -1.
@internal
int indexOfKey<K, V>(Map<K, V> map, K key) {
  var i = 0;
  for (final k in map.keys) {
    if (k == key) return i;
    i++;
  }
  return -1;
}
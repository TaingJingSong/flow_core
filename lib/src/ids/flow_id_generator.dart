import 'dart:math';

/// Generates unique identifiers for flow entities.
///
/// Implement this to plug in your own ID strategy (e.g. UUIDv7,
/// server-assigned IDs, ULIDs). The default implementation is a
/// monotonic counter with a random session prefix, which is
/// collision-resistant within a single process and readable.
abstract class FlowIdGenerator {
  /// Returns a new unique identifier.
  String next(); 
}

/// Default [FlowIdGenerator]. Produces IDs like `n_7f3a_1`.
///
/// Not cryptographically unique across machines. If you need
/// cross-device uniqueness, provide your own implementation.
class DefaultFlowIdGenerator implements FlowIdGenerator {
  /// Default [FlowIdGenerator]. Produces IDs like `n_7f3a_1`.
  DefaultFlowIdGenerator({String? prefix, int? seed}) : _prefix = prefix ?? _randomPrefix(seed);

  final String _prefix;
  int _counter = 0;

  @override
  String next() => '${_prefix}_${++_counter}';

  static String _randomPrefix(int? seed) {
    final rng = Random(seed);
    final value = rng.nextInt(0xFFFFFF);
    return value.toRadixString(16).padLeft(6, '0');
  }
}
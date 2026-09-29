import 'package:meta/meta.dart';

/// A strongly-typed identifier for a flow entity.
@immutable
class FlowId implements Comparable<FlowId> {
  const FlowId(this.value);

  final String value;

  @override
  int compareTo(FlowId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FlowId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
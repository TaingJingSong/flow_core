import 'package:meta/meta.dart';
import 'flow_label.dart';

/// Which side of a node a port attaches to.
enum FlowPortSide { top, right, bottom, left, center }

/// Direction of data flow through a port.
enum FlowPortKind { input, output, bidirectional }

/// A connection point on a node.
///
/// [name] is unique within the owning node and is what edges reference.
@immutable
class FlowPort {
  const FlowPort({
    required this.name,
    this.side = FlowPortSide.center,
    this.kind = FlowPortKind.bidirectional,
    this.position = 0.5,
    this.isConnectable = true,
    this.label,
  });

  /// Unique within the owning node. Edges reference ports by this value.
  final String name;

  final FlowPortSide side;
  final FlowPortKind kind;

  /// Position along [side] in `[0.0, 1.0]`. Ignored when [side] is `center`.
  final double position;

  final bool isConnectable;
  final FlowLabel? label;

  FlowPort copyWith({
    String? name,
    FlowPortSide? side,
    FlowPortKind? kind,
    double? position,
    bool? isConnectable,
    Object? label = _unset,
  }) =>
      FlowPort(
        name: name ?? this.name,
        side: side ?? this.side,
        kind: kind ?? this.kind,
        position: position ?? this.position,
        isConnectable: isConnectable ?? this.isConnectable,
        label: label == _unset ? this.label : label as FlowLabel?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowPort &&
          other.name == name &&
          other.side == side &&
          other.kind == kind &&
          other.position == position &&
          other.isConnectable == isConnectable &&
          other.label == label;

  @override
  int get hashCode =>
      Object.hash(name, side, kind, position, isConnectable, label);

  @override
  String toString() => 'FlowPort($name, $side, $kind)';
}

const Object _unset = Object();
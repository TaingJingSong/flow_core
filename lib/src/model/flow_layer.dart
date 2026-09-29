import 'package:meta/meta.dart';
import 'flow_id.dart';

/// A named, z-ordered container. Nodes, edges, and groups belong to exactly
/// one layer via their `layerId` field.
@immutable
class FlowLayer {
  const FlowLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.zIndex = 0,
    this.opacity = 1.0,
  });

  final FlowId id;
  final String name;
  final bool visible;
  final bool locked;
  final int zIndex;
  final double opacity;

  FlowLayer copyWith({
    FlowId? id,
    String? name,
    bool? visible,
    bool? locked,
    int? zIndex,
    double? opacity,
  }) =>
      FlowLayer(
        id: id ?? this.id,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        zIndex: zIndex ?? this.zIndex,
        opacity: opacity ?? this.opacity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowLayer &&
          other.id == id &&
          other.name == name &&
          other.visible == visible &&
          other.locked == locked &&
          other.zIndex == zIndex &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(id, name, visible, locked, zIndex, opacity);

  @override
  String toString() => 'FlowLayer($id, "$name", z: $zIndex)';
}
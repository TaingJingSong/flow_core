import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../geometry/flow_rect.dart';
import 'flow_id.dart';
import 'flow_label.dart';
import 'flow_port.dart';
import 'flow_style.dart';

const _listEq = ListEquality<FlowPort>();
const _setEq = SetEquality<String>();
const _mapEq = MapEquality<String, String>();
const _deepEq = DeepCollectionEquality();

/// A single vertex in a flow diagram.
@immutable
class FlowNode {
  const FlowNode({
    required this.id,
    required this.type,
    required this.rect,
    this.style = FlowStyle.defaults,
    this.label,
    this.ports = const <FlowPort>[],
    this.data = const <String, Object?>{},
    this.tags = const <String>{},
    this.meta = const <String, String>{},
    this.parentGroupId,
    this.layerId,
    this.namespace,
    this.zIndex = 0,
    this.locked = false,
    this.visible = true,
    this.rotation = 0.0,
  });

  final FlowId id;

  /// Semantic type, e.g. `rectangle`, `circle`, `state`, `class`, `task`.
  /// Renderers map this to a visual shape.
  final String type;

  final FlowRect rect;
  final FlowStyle style;
  final FlowLabel? label;
  final List<FlowPort> ports;

  /// Free-form payload for renderers, plugins, and format round-trips.
  /// Never mutate this map; treat it as immutable.
  final Map<String, Object?> data;

  /// Semantic labels, e.g. `actor`, `database`, `boundary`.
  final Set<String> tags;

  /// Small string key-values for annotations, e.g. stereotype metadata.
  final Map<String, String> meta;

  final FlowId? parentGroupId;
  final FlowId? layerId;

  /// Diagram module / package / subgraph namespace, if any.
  final String? namespace;

  final int zIndex;
  final bool locked;
  final bool visible;

  /// Rotation in radians around the rect center.
  final double rotation;

  FlowPort? portByName(String name) {
    for (final p in ports) {
      if (p.name == name) return p;
    }
    return null;
  }

  FlowNode copyWith({
    FlowId? id,
    String? type,
    FlowRect? rect,
    FlowStyle? style,
    Object? label = _unset,
    List<FlowPort>? ports,
    Map<String, Object?>? data,
    Set<String>? tags,
    Map<String, String>? meta,
    Object? parentGroupId = _unset,
    Object? layerId = _unset,
    Object? namespace = _unset,
    int? zIndex,
    bool? locked,
    bool? visible,
    double? rotation,
  }) =>
      FlowNode(
        id: id ?? this.id,
        type: type ?? this.type,
        rect: rect ?? this.rect,
        style: style ?? this.style,
        label: label == _unset ? this.label : label as FlowLabel?,
        ports: ports ?? this.ports,
        data: data ?? this.data,
        tags: tags ?? this.tags,
        meta: meta ?? this.meta,
        parentGroupId: parentGroupId == _unset
            ? this.parentGroupId
            : parentGroupId as FlowId?,
        layerId: layerId == _unset ? this.layerId : layerId as FlowId?,
        namespace:
            namespace == _unset ? this.namespace : namespace as String?,
        zIndex: zIndex ?? this.zIndex,
        locked: locked ?? this.locked,
        visible: visible ?? this.visible,
        rotation: rotation ?? this.rotation,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowNode &&
          other.id == id &&
          other.type == type &&
          other.rect == rect &&
          other.style == style &&
          other.label == label &&
          _listEq.equals(other.ports, ports) &&
          _deepEq.equals(other.data, data) &&
          _setEq.equals(other.tags, tags) &&
          _mapEq.equals(other.meta, meta) &&
          other.parentGroupId == parentGroupId &&
          other.layerId == layerId &&
          other.namespace == namespace &&
          other.zIndex == zIndex &&
          other.locked == locked &&
          other.visible == visible &&
          other.rotation == rotation;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        rect,
        style,
        label,
        _listEq.hash(ports),
        _deepEq.hash(data),
        _setEq.hash(tags),
        _mapEq.hash(meta),
        parentGroupId,
        layerId,
        namespace,
        zIndex,
        locked,
        visible,
        rotation,
      );

  @override
  String toString() => 'FlowNode($id, "$type")';
}

const Object _unset = Object();
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../geometry/flow_rect.dart';
import 'flow_id.dart';
import 'flow_label.dart';
import 'flow_style.dart';

const _listEq = ListEquality<FlowId>();
const _mapEq = MapEquality<String, String>();
const _deepEq = DeepCollectionEquality();

/// A container that visually and semantically groups nodes and other groups.
///
/// Membership is stored in two directions:
/// - [childNodeIds] / [childGroupIds] list children directly.
/// - Each child's `parentGroupId` points back here.
///
/// The controller is responsible for keeping both in sync.
@immutable
class FlowGroup {
  const FlowGroup({
    required this.id,
    required this.rect,
    this.label,
    this.childNodeIds = const <FlowId>[],
    this.childGroupIds = const <FlowId>[],
    this.style = FlowStyle.defaults,
    this.collapsed = false,
    this.parentGroupId,
    this.layerId,
    this.namespace,
    this.data = const <String, Object?>{},
    this.meta = const <String, String>{},
    this.zIndex = 0,
    this.locked = false,
    this.visible = true,
  });

  final FlowId id;
  final FlowRect rect;
  final FlowLabel? label;
  final List<FlowId> childNodeIds;
  final List<FlowId> childGroupIds;
  final FlowStyle style;
  final bool collapsed;

  final FlowId? parentGroupId;
  final FlowId? layerId;
  final String? namespace;

  final Map<String, Object?> data;
  final Map<String, String> meta;

  final int zIndex;
  final bool locked;
  final bool visible;

  FlowGroup copyWith({
    FlowId? id,
    FlowRect? rect,
    Object? label = _unset,
    List<FlowId>? childNodeIds,
    List<FlowId>? childGroupIds,
    FlowStyle? style,
    bool? collapsed,
    Object? parentGroupId = _unset,
    Object? layerId = _unset,
    Object? namespace = _unset,
    Map<String, Object?>? data,
    Map<String, String>? meta,
    int? zIndex,
    bool? locked,
    bool? visible,
  }) =>
      FlowGroup(
        id: id ?? this.id,
        rect: rect ?? this.rect,
        label: label == _unset ? this.label : label as FlowLabel?,
        childNodeIds: childNodeIds ?? this.childNodeIds,
        childGroupIds: childGroupIds ?? this.childGroupIds,
        style: style ?? this.style,
        collapsed: collapsed ?? this.collapsed,
        parentGroupId: parentGroupId == _unset
            ? this.parentGroupId
            : parentGroupId as FlowId?,
        layerId: layerId == _unset ? this.layerId : layerId as FlowId?,
        namespace:
            namespace == _unset ? this.namespace : namespace as String?,
        data: data ?? this.data,
        meta: meta ?? this.meta,
        zIndex: zIndex ?? this.zIndex,
        locked: locked ?? this.locked,
        visible: visible ?? this.visible,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowGroup &&
          other.id == id &&
          other.rect == rect &&
          other.label == label &&
          _listEq.equals(other.childNodeIds, childNodeIds) &&
          _listEq.equals(other.childGroupIds, childGroupIds) &&
          other.style == style &&
          other.collapsed == collapsed &&
          other.parentGroupId == parentGroupId &&
          other.layerId == layerId &&
          other.namespace == namespace &&
          _deepEq.equals(other.data, data) &&
          _mapEq.equals(other.meta, meta) &&
          other.zIndex == zIndex &&
          other.locked == locked &&
          other.visible == visible;

  @override
  int get hashCode => Object.hash(
        id,
        rect,
        label,
        _listEq.hash(childNodeIds),
        _listEq.hash(childGroupIds),
        style,
        collapsed,
        parentGroupId,
        layerId,
        namespace,
        _deepEq.hash(data),
        _mapEq.hash(meta),
        zIndex,
        locked,
        visible,
      );

  @override
  String toString() =>
      'FlowGroup($id, nodes: ${childNodeIds.length}, groups: ${childGroupIds.length})';
}

const Object _unset = Object();
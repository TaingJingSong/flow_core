import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../model/flow_id.dart';

const _setEq = SetEquality<FlowId>();

/// Immutable snapshot of what is currently selected.
@immutable
class FlowSelection {
  FlowSelection({
    Set<FlowId>? nodeIds,
    Set<FlowId>? edgeIds,
    Set<FlowId>? groupIds,
  })  : nodeIds = Set.unmodifiable(nodeIds ?? const <FlowId>{}),
        edgeIds = Set.unmodifiable(edgeIds ?? const <FlowId>{}),
        groupIds = Set.unmodifiable(groupIds ?? const <FlowId>{});

  static final FlowSelection empty = FlowSelection();

  final Set<FlowId> nodeIds;
  final Set<FlowId> edgeIds;
  final Set<FlowId> groupIds;

  bool get isEmpty => nodeIds.isEmpty && edgeIds.isEmpty && groupIds.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => nodeIds.length + edgeIds.length + groupIds.length;

  bool containsNode(FlowId id) => nodeIds.contains(id);
  bool containsEdge(FlowId id) => edgeIds.contains(id);
  bool containsGroup(FlowId id) => groupIds.contains(id);

  FlowSelection add({
    Iterable<FlowId>? nodes,
    Iterable<FlowId>? edges,
    Iterable<FlowId>? groups,
  }) =>
      FlowSelection(
        nodeIds: {...nodeIds, ...?nodes},
        edgeIds: {...edgeIds, ...?edges},
        groupIds: {...groupIds, ...?groups},
      );

  FlowSelection remove({
    Iterable<FlowId>? nodes,
    Iterable<FlowId>? edges,
    Iterable<FlowId>? groups,
  }) =>
      FlowSelection(
        nodeIds: {...nodeIds}..removeAll(nodes ?? const []),
        edgeIds: {...edgeIds}..removeAll(edges ?? const []),
        groupIds: {...groupIds}..removeAll(groups ?? const []),
      );

  FlowSelection only({
    Iterable<FlowId>? nodes,
    Iterable<FlowId>? edges,
    Iterable<FlowId>? groups,
  }) =>
      FlowSelection(
        nodeIds: {...?nodes},
        edgeIds: {...?edges},
        groupIds: {...?groups},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowSelection &&
          _setEq.equals(other.nodeIds, nodeIds) &&
          _setEq.equals(other.edgeIds, edgeIds) &&
          _setEq.equals(other.groupIds, groupIds);

  @override
  int get hashCode =>
      Object.hash(_setEq.hash(nodeIds), _setEq.hash(edgeIds), _setEq.hash(groupIds));

  @override
  String toString() =>
      'FlowSelection(nodes: ${nodeIds.length}, edges: ${edgeIds.length}, '
      'groups: ${groupIds.length})';
}
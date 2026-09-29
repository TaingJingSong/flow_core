import 'dart:async';

import '../commands/builtin/add_edge_command.dart';
import '../commands/builtin/add_node_command.dart';
import '../commands/builtin/move_nodes_command.dart';
import '../commands/builtin/remove_edge_command.dart';
import '../commands/builtin/remove_node_command.dart';
import '../commands/builtin/set_node_rect_command.dart';
import '../commands/builtin/set_node_style_command.dart';
import '../commands/flow_command.dart';
import '../commands/flow_command_stack.dart';
import '../commands/flow_document_state.dart';
import '../commands/flow_history_event.dart';
import '../geometry/flow_point.dart';
import '../geometry/flow_rect.dart';
import '../ids/flow_id_generator.dart';
import '../model/flow_document.dart';
import '../model/flow_edge.dart';
import '../model/flow_id.dart';
import '../model/flow_node.dart';
import '../model/flow_page.dart';
import '../model/flow_style.dart';
import '../selection/flow_selection.dart';
import 'flow_event.dart';

/// The single public entry point for reading and mutating a [FlowDocument].
///
/// Everything a UI needs lives here:
///
/// - Load, replace, or reset a document.
/// - Query nodes, edges, groups, and selections.
/// - Perform editing operations (add, move, resize, connect, style, delete).
/// - Manage selection.
/// - Undo, redo, and transactions.
/// - Subscribe to a unified event stream.
///
/// This class has no dependency on Flutter. Wrap it in a `ChangeNotifier`,
/// `ValueListenable`, or any state-management solution you like.
class FlowController {
  FlowController({
    required FlowDocument document,
    FlowIdGenerator? idGenerator,
    int historyLimit = 200,
    Duration mergeWindow = const Duration(milliseconds: 500),
    DateTime Function()? now,
  })  : _state = FlowDocumentState(document),
        _idGenerator = idGenerator ?? DefaultFlowIdGenerator() {
    _stack = FlowCommandStack(
      state: _state,
      historyLimit: historyLimit,
      mergeWindow: mergeWindow,
      now: now,
    );
    _historySub = _stack.events.listen(_onHistory);
  }

  /// Convenience constructor for a brand-new empty document.
  factory FlowController.empty({
    FlowIdGenerator? idGenerator,
    int historyLimit = 200,
    Duration mergeWindow = const Duration(milliseconds: 500),
  }) =>
      FlowController(
        document: FlowDocument.empty(),
        idGenerator: idGenerator,
        historyLimit: historyLimit,
        mergeWindow: mergeWindow,
      );

  final FlowDocumentState _state;
  late final FlowCommandStack _stack;
  final FlowIdGenerator _idGenerator;
  final StreamController<FlowEvent> _events =
      StreamController<FlowEvent>.broadcast();
  late final StreamSubscription<FlowHistoryEvent> _historySub;

  FlowSelection _selection = FlowSelection.empty;
  FlowId? _activePageId;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Document access
  // ---------------------------------------------------------------------------

  /// The current immutable document.
  FlowDocument get document => _state.document;

  /// The active page, or the first page if none is set.
  FlowPage? get activePage {
    final id = _activePageId;
    if (id != null) {
      final page = _state.document.pageById(id);
      if (page != null) return page;
    }
    return _state.document.firstPage;
  }

  /// ID of the currently active page.
  FlowId? get activePageId => activePage?.id;

  /// Sets the active page. Fires [DocumentChanged] so views can rebuild.
  void setActivePage(FlowId pageId) {
    if (_state.document.pageById(pageId) == null) return;
    if (_activePageId == pageId) return;
    _activePageId = pageId;
    _events.add(DocumentChanged(_state.document));
  }

  /// Replaces the entire document and resets history and selection.
  void loadDocument(FlowDocument document) {
    _state.document = document;
    _stack.clear();
    _selection = FlowSelection.empty;
    _activePageId = null;
    _events.add(DocumentChanged(document));
    _events.add(SelectionChanged(_selection));
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns the node with [id] on the active page, or null.
  FlowNode? node(FlowId id) => activePage?.nodes[id];

  /// Returns the edge with [id] on the active page, or null.
  FlowEdge? edge(FlowId id) => activePage?.edges[id];

  /// Returns every node on the active page.
  Iterable<FlowNode> get allNodes =>
      activePage?.nodes.values ?? const Iterable<FlowNode>.empty();

  /// Returns every edge on the active page.
  Iterable<FlowEdge> get allEdges =>
      activePage?.edges.values ?? const Iterable<FlowEdge>.empty();

  /// Returns every edge whose source or target is [nodeId].
  Iterable<FlowEdge> edgesFor(FlowId nodeId) sync* {
    final page = activePage;
    if (page == null) return;
    for (final e in page.edges.values) {
      if (e.connects(nodeId)) yield e;
    }
  }

  /// Returns every node whose rect contains [point], bottom-most first.
  Iterable<FlowNode> nodesAt(FlowPoint point) sync* {
    final page = activePage;
    if (page == null) return;
    final sorted = page.nodes.values.toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final n in sorted) {
      if (!n.visible) continue;
      if (n.rect.contains(point)) yield n;
    }
  }

  /// Returns every node whose rect intersects [rect].
  Iterable<FlowNode> nodesIntersecting(FlowRect rect) sync* {
    final page = activePage;
    if (page == null) return;
    for (final n in page.nodes.values) {
      if (!n.visible) continue;
      if (n.rect.intersects(rect)) yield n;
    }
  }

  /// Bounding box of every node on the active page, or null if empty.
  FlowRect? contentBounds() {
    final page = activePage;
    if (page == null || page.nodes.isEmpty) return null;
    FlowRect? acc;
    for (final n in page.nodes.values) {
      acc = acc == null ? n.rect : acc.union(n.rect);
    }
    return acc;
  }

  // ---------------------------------------------------------------------------
  // ID generation
  // ---------------------------------------------------------------------------

  /// Returns a fresh, unique [FlowId].
  FlowId nextId() => FlowId(_idGenerator.next());

  // ---------------------------------------------------------------------------
  // Editing API
  // ---------------------------------------------------------------------------

  /// Adds [node] to the active page.
  void addNode(FlowNode node) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(AddNodeCommand(pageId: page.id, node: node));
    _clearSelectionIfDead();
  }

  /// Removes [nodeId] and any edge incident to it.
  void removeNode(FlowId nodeId) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(RemoveNodeCommand(pageId: page.id, nodeId: nodeId));
    _selection = _selection.remove(nodes: [nodeId]);
    _clearSelectionIfDead();
  }

  /// Removes every currently selected node and edge.
  void removeSelection() {
    final page = activePage;
    if (page == null) return;
    final sel = _selection;
    if (sel.isEmpty) return;

    final commands = <FlowCommand>[
      for (final id in sel.edgeIds)
        RemoveEdgeCommand(pageId: page.id, edgeId: id),
      for (final id in sel.nodeIds)
        RemoveNodeCommand(pageId: page.id, nodeId: id),
    ];
    if (commands.isEmpty) return;

    _stack.executeAll(commands);
    _selection = FlowSelection.empty;
    _events.add(SelectionChanged(_selection));
  }

  /// Moves every node in [nodeIds] by [delta].
  ///
  /// Consecutive calls within the merge window collapse into one undo entry.
  void moveNodes(Iterable<FlowId> nodeIds, FlowPoint delta) {
    final page = activePage;
    if (page == null) return;
    final ids = nodeIds.toList(growable: false);
    if (ids.isEmpty) return;
    if (delta == FlowPoint.zero) return;
    _stack.execute(
      MoveNodesCommand(pageId: page.id, nodeIds: ids, delta: delta),
    );
  }

  /// Sets the absolute rect of a node.
  void setNodeRect(FlowId nodeId, FlowRect rect) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(
      SetNodeRectCommand(pageId: page.id, nodeId: nodeId, rect: rect),
    );
  }

  /// Replaces the style of a node.
  void setNodeStyle(FlowId nodeId, FlowStyle style) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(
      SetNodeStyleCommand(pageId: page.id, nodeId: nodeId, style: style),
    );
  }

  /// Adds an edge between two existing nodes.
  void addEdge(FlowEdge edge) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(AddEdgeCommand(pageId: page.id, edge: edge));
  }

  /// Removes an edge.
  void removeEdge(FlowId edgeId) {
    final page = activePage;
    if (page == null) return;
    _stack.execute(RemoveEdgeCommand(pageId: page.id, edgeId: edgeId));
    _selection = _selection.remove(edges: [edgeId]);
    _clearSelectionIfDead();
  }

  /// Executes a command directly. Escape hatch for custom commands.
  void executeCommand(FlowCommand command) {
    _stack.execute(command);
    _clearSelectionIfDead();
  }

  /// Executes several commands as a single atomic unit.
  void executeAll(List<FlowCommand> commands) {
    if (commands.isEmpty) return;
    _stack.executeAll(commands);
    _clearSelectionIfDead();
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  /// The current selection.
  FlowSelection get selection => _selection;

  /// Replaces the selection with [selection].
  void setSelection(FlowSelection selection) {
    if (_selection == selection) return;
    _selection = selection;
    _events.add(SelectionChanged(_selection));
  }

  /// Clears the selection.
  void clearSelection() => setSelection(FlowSelection.empty);

  /// Selects a single node.
  void selectNode(FlowId nodeId) =>
      setSelection(FlowSelection(nodeIds: {nodeId}));

  /// Selects a single edge.
  void selectEdge(FlowId edgeId) =>
      setSelection(FlowSelection(edgeIds: {edgeId}));

  /// Adds a node to the current selection.
  void addNodeToSelection(FlowId nodeId) =>
      setSelection(_selection.add(nodes: [nodeId]));

  /// Adds an edge to the current selection.
  void addEdgeToSelection(FlowId edgeId) =>
      setSelection(_selection.add(edges: [edgeId]));

  /// Toggles a node in the selection.
  void toggleNodeSelection(FlowId nodeId) {
    final next = _selection.containsNode(nodeId)
        ? _selection.remove(nodes: [nodeId])
        : _selection.add(nodes: [nodeId]);
    setSelection(next);
  }

  /// Toggles an edge in the selection.
  void toggleEdgeSelection(FlowId edgeId) {
    final next = _selection.containsEdge(edgeId)
        ? _selection.remove(edges: [edgeId])
        : _selection.add(edges: [edgeId]);
    setSelection(next);
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  bool get canUndo => _stack.canUndo;
  bool get canRedo => _stack.canRedo;
  int get undoLength => _stack.undoLength;
  int get redoLength => _stack.redoLength;

  void undo() {
    _stack.undo();
    _clearSelectionIfDead();
  }

  void redo() {
    _stack.redo();
    _clearSelectionIfDead();
  }

  void clearHistory() => _stack.clear();

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  List<FlowCommand>? _transactionBuffer;

  /// Whether a transaction is currently open.
  bool get inTransaction => _transactionBuffer != null;

  /// Begins a transaction. Commands are buffered until [commitTransaction].
  ///
  /// Nested calls are not supported; a second [beginTransaction] while one
  /// is open is a no-op.
  void beginTransaction() {
    if (_transactionBuffer != null) return;
    _transactionBuffer = <FlowCommand>[];
  }

  /// Commits the current transaction as a single undoable unit.
  ///
  /// Returns the number of commands committed.
  int commitTransaction() {
    final buffer = _transactionBuffer;
    if (buffer == null) return 0;
    _transactionBuffer = null;
    if (buffer.isEmpty) return 0;
    _stack.executeAll(buffer);
    _clearSelectionIfDead();
    return buffer.length;
  }

  /// Discards the current transaction without applying anything.
  void rollbackTransaction() {
    _transactionBuffer = null;
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Unified stream of controller events.
  Stream<FlowEvent> get events => _events.stream;

  /// Convenience filter for [DocumentChanged].
  Stream<DocumentChanged> get documentChanges =>
      _events.stream.where((e) => e is DocumentChanged).cast<DocumentChanged>();

  /// Convenience filter for [SelectionChanged].
  Stream<SelectionChanged> get selectionChanges =>
      _events.stream.where((e) => e is SelectionChanged).cast<SelectionChanged>();

  /// Convenience filter for [HistoryChanged].
  Stream<HistoryChanged> get historyChanges =>
      _events.stream.where((e) => e is HistoryChanged).cast<HistoryChanged>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Releases resources. The controller is unusable after this call.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _historySub.cancel();
    _events.close();
    _stack.dispose();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _onHistory(FlowHistoryEvent e) {
    if (_disposed) return;
    _events.add(HistoryChanged(
      canUndo: e.canUndo,
      canRedo: e.canRedo,
      undoLength: e.undoLength,
      redoLength: e.redoLength,
      lastLabel: e.lastLabel,
    ));

    // Every command can change the document; keep views that only listen
    // to document changes in sync.
    _events.add(DocumentChanged(_state.document));
    final pageId = activePageId;
    if (pageId != null) {
      _events.add(PageChanged(pageId, label: e.lastLabel));
    }
  }

  /// Drops any selected ids that no longer exist on the active page.
  void _clearSelectionIfDead() {
    final page = activePage;
    if (page == null) {
      if (_selection.isNotEmpty) setSelection(FlowSelection.empty);
      return;
    }
    final liveNodes = page.nodes.keys.toSet();
    final liveEdges = page.edges.keys.toSet();
    final liveGroups = page.groups.keys.toSet();

    final nodesOk = _selection.nodeIds.every(liveNodes.contains);
    final edgesOk = _selection.edgeIds.every(liveEdges.contains);
    final groupsOk = _selection.groupIds.every(liveGroups.contains);
    if (nodesOk && edgesOk && groupsOk) return;

    final pruned = FlowSelection(
      nodeIds: _selection.nodeIds.where(liveNodes.contains).toSet(),
      edgeIds: _selection.edgeIds.where(liveEdges.contains).toSet(),
      groupIds: _selection.groupIds.where(liveGroups.contains).toSet(),
    );
    setSelection(pruned);
  }
}
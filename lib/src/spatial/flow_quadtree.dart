import '../geometry/flow_rect.dart';

/// A dynamic quadtree keyed by bounding boxes.
///
/// - Items whose bounds fit entirely in a single child go to that child.
/// - Items that straddle a boundary stay at the current node.
/// - If an inserted item's bounds fall outside the current root, the
///   root expands and the tree rebuilds.
///
/// Not thread-safe. Queries return items whose stored bounds intersect
/// the query rect; callers must perform exact hit testing on the results.
class FlowQuadtree<T> {
  FlowQuadtree({
    required FlowRect bounds,
    this.capacity = 8,
    this.maxDepth = 8,
  })  : _bounds = bounds,
        _root = _QuadNode<T>(
          bounds: bounds,
          depth: 0,
          capacity: capacity,
          maxDepth: maxDepth,
        );

  /// An empty tree that expands on first insert.
  factory FlowQuadtree.empty({int capacity = 8, int maxDepth = 8}) =>
      FlowQuadtree<T>(
        bounds: FlowRect.zero,
        capacity: capacity,
        maxDepth: maxDepth,
      );

  final int capacity;
  final int maxDepth;

  FlowRect _bounds;
  _QuadNode<T> _root;
  int _length = 0;

  /// The current root bounds. Expands automatically as items are inserted.
  FlowRect get bounds => _bounds;

  /// Number of items in the tree.
  int get length => _length;

  /// Whether the tree is empty.
  bool get isEmpty => _length == 0;

  /// Inserts [item] with its bounding box [itemBounds].
  ///
  /// Item bounds must be a valid, non-degenerate rect (width and height
  /// greater than or equal to zero).
  void insert(T item, FlowRect itemBounds) {
    if (!_bounds.containsRect(itemBounds)) {
      _expandTo(itemBounds);
    }
    _root.insert(item, itemBounds);
    _length++;
  }

  /// Returns every item whose stored bounds intersect [range].
  List<T> query(FlowRect range) {
    final out = <T>[];
    _root.query(range, out);
    return out;
  }

  /// Removes all items.
  void clear() {
    _root = _QuadNode<T>(
      bounds: FlowRect.zero,
      depth: 0,
      capacity: capacity,
      maxDepth: maxDepth,
    );
    _bounds = FlowRect.zero;
    _length = 0;
  }

  void _expandTo(FlowRect itemBounds) {
    final entries = <_Entry<T>>[];
    _root.collectAll(entries);

    final newBounds = _bounds.isEmpty
        ? itemBounds
        : _bounds.union(itemBounds);

    _root = _QuadNode<T>(
      bounds: newBounds,
      depth: 0,
      capacity: capacity,
      maxDepth: maxDepth,
    );
    _bounds = newBounds;

    for (final e in entries) {
      _root.insert(e.item, e.bounds);
    }
  }
}

class _Entry<T> {
  _Entry(this.item, this.bounds);
  final T item;
  final FlowRect bounds;
}

class _QuadNode<T> {
  _QuadNode({
    required this.bounds,
    required this.depth,
    required this.capacity,
    required this.maxDepth,
  });

  final FlowRect bounds;
  final int depth;
  final int capacity;
  final int maxDepth;

  final List<_Entry<T>> _items = <_Entry<T>>[];
  _QuadNode<T>? _nw;
  _QuadNode<T>? _ne;
  _QuadNode<T>? _sw;
  _QuadNode<T>? _se;

  bool get isLeaf => _nw == null;
  bool get canSplit => depth < maxDepth;

  bool insert(T item, FlowRect itemBounds) {
    if (!bounds.intersects(itemBounds)) return false;
    if (!isLeaf) {
      final child = _childContaining(itemBounds);
      if (child != null) return child.insert(item, itemBounds);
    }
    _insertHere(_Entry<T>(item, itemBounds));
    return true;
  }

  void query(FlowRect range, List<T> out) {
    if (!bounds.intersects(range)) return;
    for (final e in _items) {
      if (e.bounds.intersects(range)) out.add(e.item);
    }
    if (!isLeaf) {
      _nw!.query(range, out);
      _ne!.query(range, out);
      _sw!.query(range, out);
      _se!.query(range, out);
    }
  }

  void collectAll(List<_Entry<T>> out) {
    out.addAll(_items);
    if (!isLeaf) {
      _nw!.collectAll(out);
      _ne!.collectAll(out);
      _sw!.collectAll(out);
      _se!.collectAll(out);
    }
  }

  void _insertHere(_Entry<T> entry) {
    _items.add(entry);
    if (_items.length > capacity && isLeaf && canSplit) {
      _split();
      _redistribute();
    }
  }

  void _split() {
    final hw = bounds.width / 2;
    final hh = bounds.height / 2;
    final l = bounds.left;
    final t = bounds.top;
    _nw = _QuadNode<T>(
      bounds: FlowRect.fromLTWH(l, t, hw, hh),
      depth: depth + 1,
      capacity: capacity,
      maxDepth: maxDepth,
    );
    _ne = _QuadNode<T>(
      bounds: FlowRect.fromLTWH(l + hw, t, hw, hh),
      depth: depth + 1,
      capacity: capacity,
      maxDepth: maxDepth,
    );
    _sw = _QuadNode<T>(
      bounds: FlowRect.fromLTWH(l, t + hh, hw, hh),
      depth: depth + 1,
      capacity: capacity,
      maxDepth: maxDepth,
    );
    _se = _QuadNode<T>(
      bounds: FlowRect.fromLTWH(l + hw, t + hh, hw, hh),
      depth: depth + 1,
      capacity: capacity,
      maxDepth: maxDepth,
    );
  }

  void _redistribute() {
    final kept = <_Entry<T>>[];
    for (final e in _items) {
      final child = _childContaining(e.bounds);
      if (child == null) {
        kept.add(e);
      } else {
        child._insertHere(e);
      }
    }
    _items
      ..clear()
      ..addAll(kept);
  }

  _QuadNode<T>? _childContaining(FlowRect r) {
    if (_nw!.bounds.containsRect(r)) return _nw;
    if (_ne!.bounds.containsRect(r)) return _ne;
    if (_sw!.bounds.containsRect(r)) return _sw;
    if (_se!.bounds.containsRect(r)) return _se;
    return null;
  }
}
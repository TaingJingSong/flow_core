import 'dart:math' as math;

import '../../geometry/flow_rect.dart';
import '../../model/flow_id.dart';
import '../flow_layout_engine.dart';
import '../flow_layout_input.dart';
import '../flow_layout_result.dart';

/// Places nodes on a regular grid, filling rows left-to-right.
///
/// The number of columns defaults to `ceil(sqrt(n))`.
class GridLayout extends FlowLayoutEngine {
  const GridLayout({this.columns});

  /// Fixed column count. When null, computed from node count.
  final int? columns;

  @override
  String get id => 'grid';

  @override
  String get name => 'Grid';

  @override
  FlowLayoutResult layout(FlowLayoutInput input) {
    if (input.nodes.isEmpty) return FlowLayoutResult(<FlowId, FlowRect>{});

    final n = input.nodes.length;
    final cols = columns ?? math.sqrt(n).ceil();
    final spacing = input.spacing;

    // Column widths and row heights.
    final colWidth = List<double>.filled(cols, 0);
    final rowHeight = List<double>.filled(((n - 1) ~/ cols) + 1, 0);
    for (var i = 0; i < n; i++) {
      final node = input.nodes[i];
      final c = i % cols;
      final r = i ~/ cols;
      if (node.size.width > colWidth[c]) colWidth[c] = node.size.width;
      if (node.size.height > rowHeight[r]) rowHeight[r] = node.size.height;
    }

    final colX = List<double>.filled(cols, spacing.padding);
    for (var c = 1; c < cols; c++) {
      colX[c] = colX[c - 1] + colWidth[c - 1] + spacing.nodeSpacing;
    }
    final rowY = List<double>.filled(rowHeight.length, spacing.padding);
    for (var r = 1; r < rowHeight.length; r++) {
      rowY[r] = rowY[r - 1] + rowHeight[r - 1] + spacing.layerSpacing;
    }

    final rects = <FlowId, FlowRect>{};
    for (var i = 0; i < n; i++) {
      final node = input.nodes[i];
      final c = i % cols;
      final r = i ~/ cols;
      rects[node.id] = FlowRect.fromLTWH(
        colX[c],
        rowY[r],
        node.size.width,
        node.size.height,
      );
    }
    for (final entry in input.pinnedRects.entries) {
      rects[entry.key] = entry.value;
    }
    return FlowLayoutResult(rects);
  }
}
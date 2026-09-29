/// Direction of layer growth for hierarchical layouts.
enum FlowLayoutDirection {
  /// Layers grow top → bottom (e.g. Mermaid `flowchart TD`).
  topToBottom,

  /// Layers grow bottom → top (e.g. Mermaid `flowchart BT`).
  bottomToTop,

  /// Layers grow left → right (e.g. Mermaid `flowchart LR`).
  leftToRight,

  /// Layers grow right → left (e.g. Mermaid `flowchart RL`).
  rightToLeft,
}

extension FlowLayoutDirectionX on FlowLayoutDirection {
  /// True when layers grow along the vertical axis.
  bool get isVertical =>
      this == FlowLayoutDirection.topToBottom ||
      this == FlowLayoutDirection.bottomToTop;

  /// True when layers grow along the horizontal axis.
  bool get isHorizontal => !isVertical;

  /// Multiplier applied to layer indices. `1` for TD / LR, `-1` for BT / RL.
  int get layerSign =>
      this == FlowLayoutDirection.bottomToTop ||
              this == FlowLayoutDirection.rightToLeft
          ? -1
          : 1;
}
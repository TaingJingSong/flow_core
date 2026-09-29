/// Semantic kind of an edge. Renderers and layout engines may use this
/// for styling and for format-specific round-trips.
enum FlowEdgeKind {
  /// Generic flowchart arrow.
  flow,

  /// UML association.
  association,

  /// UML inheritance / extends / implements.
  inheritance,

  /// UML composition (filled diamond at source).
  composition,

  /// UML aggregation (hollow diamond at source).
  aggregation,

  /// UML dependency.
  dependency,

  /// State machine transition.
  transition,

  /// Sequence diagram message.
  message,

  /// BPMN sequence flow.
  sequenceFlow,

  /// BPMN message flow.
  messageFlow,

  /// Simple undirected link.
  link,

  /// Custom kind; see `FlowEdge.meta['kind']` for a hint.
  custom,
}
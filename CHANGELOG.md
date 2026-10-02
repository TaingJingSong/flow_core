# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-02

### Added

- **Document Object Model (DOM)**
  - Immutable graph hierarchy: `FlowDocument`, `FlowPage`, `FlowNode`, `FlowEdge`, `FlowGroup`, `FlowLayer`, `FlowPort`, and `FlowLabel`.
  - Strongly-typed identifiers via `FlowId` and generator strategies (`FlowIdGenerator`, `DefaultFlowIdGenerator`).
  - Styling primitives: `FlowStyle`, `FlowTextStyle`, `FlowColor`, `FlowShadow`, and arrowheads (`FlowArrowHead`: `none`, `triangle`, `open`, `diamond`, `circle`).
  - Multi-page and multi-layer management with visibility, locking, and z-index ordering.
  - Connection ports (`FlowPort`) with configurable side (`top`, `right`, `bottom`, `left`, `center`), kind (`input`, `output`, `bidirectional`), and relative positioning.
  - Hierarchical grouping (`FlowGroup`) with parent-child relationships and automatic bounding-box aggregation.

- **Reactive Controller & Selection**
  - Headless `FlowController` orchestrating document mutations, selection state, and undo/redo without any Flutter UI dependency.
  - `FlowSelection` supporting single-select, multi-select, toggle selection, and collective bounding-box calculations.
  - Unified reactive event stream (`FlowEvent`) notifying listeners on document changes, selection changes, and command history events.

- **Command Architecture & History**
  - `FlowCommandStack` with undo/redo, configurable merge windows for rapid continuous edits, history depth limit, and atomic transactions.
  - Transaction batching (`beginTransaction`, `commitTransaction`, `rollbackTransaction`).
  - Built-in commands: `AddNodeCommand`, `RemoveNodeCommand`, `MoveNodesCommand`, `SetNodeRectCommand`, `SetNodeStyleCommand`, `AddEdgeCommand`, `RemoveEdgeCommand`.

- **Geometry & Spatial Indexing**
  - Primitives: `FlowPoint`, `FlowRect`, `FlowSize`.
  - Spatial math utilities: segment intersection, projection, point-to-line distances, port anchor resolution (`PortGeometry`), and edge geometry calculations (`EdgeGeometry`).
  - 2D `FlowQuadTree` spatial index implementation for $O(\log N)$ viewport culling, broadphase queries, and high-frequency canvas interactions.

- **Interactive Hit Testing**
  - `FlowHitTester` providing precise, tolerance-aware hit testing across nodes, edges, ports, and labels.
  - Z-order aware results with convenience getters: `topNode`, `topEdge`, `topPort`.

- **Edge Routing**
  - Extensible `FlowEdgeRouter` interface and `FlowRouterRegistry`.
  - Built-in routing strategies:
    - `StraightRouter`: Direct line connections.
    - `BezierRouter`: Smooth cubic Bézier paths with automatic tangent alignment.
    - `OrthogonalRouter`: Manhattan-style orthogonal routing honoring manual waypoints and port orientations.

- **Automatic Graph Layout**
  - Extensible `FlowLayoutEngine` interface and `FlowLayoutRegistry`.
  - Built-in layout engines:
    - `LayeredLayout`: Sugiyama-style hierarchical layout for directed acyclic graphs (DAGs) with cycle-breaking, layer assignment, crossing reduction, and coordinate assignment across all 4 directions (`topToBottom`, `bottomToTop`, `leftToRight`, `rightToLeft`).
    - `TreeLayout`: Reingold-Tilford / Walker style tree layouts for hierarchical structures.
    - `GridLayout`: Matrix placement with configurable column count, cell spacing, and alignment.
    - `CircularLayout`: Radial node placement around a center origin.
  - `applyLayout` utility to apply layout results directly onto documents or pages.

- **Format Interoperability & Intermediate Representation (IR)**
  - `FlowGraph` format-agnostic intermediate representation.
  - `FlowGraphConverter` and `documentToFlowGraph` for bidirectional conversions between external formats and `FlowDocument` with auto-layout integration.
  - Extensible `FlowImportPipeline` and `FlowExportPipeline`.
  - **Mermaid Flowchart** format support (`MermaidFlowchartFormat`): Parse and emit Mermaid syntax (`graph` / `flowchart`), subgraphs, node shapes (rectangles, rounded, stadiums, subroutines, cylinders, circles, diamonds, hexagons, parallelograms, trapezoids), edge kinds, and styling.
  - **Graphviz DOT** format support (`GraphvizDotFormat`): Lexer, parser, and emitter for `.dot` and `.gv` files supporting strict/non-strict digraphs, node/edge attributes, ports, and subgraphs.
  - **draw.io / diagrams.net** format support (`DrawioXmlFormat`): Parser and serializer for uncompressed `mxGraphModel` XML files (`.drawio`, `.xml`).

- **Serialization & Schema Migrations**
  - `FlowJsonCodec` with round-trip lossless encoding, stable key ordering, and compact diffable JSON.
  - Schema migration runner (`FlowMigrations`) targeting normative Schema Version 1 (`docs/schema.md`).

- **Testing & Benchmarking**
  - Comprehensive unit test suite with 210+ tests covering models, commands, geometry, spatial indexing, layout engines, routers, serialization, and format conversions.
  - Benchmark test harness evaluating 1,000-node graph layout, serialization, and end-to-end import pipelines.

# flow_core

A high-performance, pure Dart headless engine for building diagram editors, workflow canvases, flowchart tools, and node-based graph applications.

[![Dart](https://img.shields.io/badge/Dart-3.4%2B-blue.svg)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart%20VM%20%7C%20Web-blue)](https://flutter.dev)
[![Tests](https://img.shields.io/badge/Tests-210%2B%20Passing-brightgreen.svg)](#running-tests)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Overview

`flow_core` provides the foundational architecture needed to build robust visual editors without coupling business logic to any specific rendering framework. It has **zero Flutter UI dependencies**, allowing you to use it in Flutter apps (with CustomPainter or widget trees), command-line tools, server-side graph pipelines, or web applications.

### Key Highlights

- **Headless & UI-Agnostic**: Decouples diagram state, layout, routing, and history from UI widgets.
- **Rich Document Object Model**: Multi-page, multi-layer documents with nodes, connection ports, directed edges, labels, visual styles, and nested groups.
- **Transactional Undo / Redo**: Command-based history stack with configurable merge windows and atomic transactions.
- **Built-in Auto-Layout**: Sugiyama-style layered DAG layout, tree layout, matrix grid layout, and circular layout.
- **Edge Routing**: Orthogonal Manhattan routing with waypoint preservation, smooth cubic Bézier curves, and straight line routers.
- **Spatial Indexing & Hit-Testing**: Dynamic 2D Quadtree for $O(\log N)$ viewport culling and sub-millisecond multi-target hit testing.
- **Format Interoperability**: Parse and export **Mermaid Flowcharts**, **Graphviz DOT**, and **draw.io (diagrams.net) XML** via a canonical Intermediate Representation (`FlowGraph`).
- **Lossless Serialization**: Fast, diffable, round-trip JSON codec with schema migration support.
- **Benchmarked for Scale**: Sub-second layouts and sub-50ms serialization on 1,000+ node graphs.

---

## Architecture

```text
┌────────────────────────────────────────────────────────┐
│                   Format Interop                       │
│    Mermaid Flowchart  │  Graphviz DOT  │  draw.io XML  │
└───────────────────────────┬────────────────────────────┘
                            │ (Parse / Emit)
                            ▼
┌────────────────────────────────────────────────────────┐
│              FlowGraph (Intermediate Rep)             │
└───────────────────────────┬────────────────────────────┘
                            │ (FlowGraphConverter)
                            ▼
┌────────────────────────────────────────────────────────┐
│               FlowDocument Model (DOM)                 │
│  Pages ──► Layers ──► Groups ──► Nodes ──► Ports ──►   │
│            Edges ──► Labels ──► Styles                 │
└─────────────┬───────────────────────────┬──────────────┘
              │                           │
              ▼                           ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│      FlowController       │ │    Spatial & Routing     │
│ ───────────────────────── │ │ ──────────────────────── │
│ • Command Stack (Undo/Redo│ │ • FlowQuadtree (2D Index)│
│ • Transaction Batching    │ │ • FlowHitTester          │
│ • Selection Management    │ │ • Edge Routers (Manhattan│
│ • Reactive Event Stream   │ │   Bezier, Straight)      │
│ • Auto-Layout Engines     │ │                          │
└───────────────────────────┘ └──────────────────────────┘
```

---

## Installation

Add `flow_core` to your `pubspec.yaml`:

```yaml
dependencies:
  flow_core:
    path: ../flow_core # or git / pub dependency
```

Import the package in your Dart code:

```dart
import 'package:flow_core/flow_core.dart';
```

---

## Quick Start & Examples

### 1. Creating a Flow Document

Build a document with nodes, ports, and connected edges:

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  // Define nodes with ports and labels
  final startNode = FlowNode(
    id: const FlowId('start'),
    type: 'process',
    rect: const FlowRect.fromLTWH(50, 100, 140, 60),
    label: const FlowLabel(text: 'Start Process'),
    ports: const [
      FlowPort(
        name: 'out',
        side: FlowPortSide.right,
        kind: FlowPortKind.output,
      ),
    ],
  );

  final endNode = FlowNode(
    id: const FlowId('end'),
    type: 'process',
    rect: const FlowRect.fromLTWH(300, 100, 140, 60),
    label: const FlowLabel(text: 'Complete'),
    ports: const [
      FlowPort(
        name: 'in',
        side: FlowPortSide.left,
        kind: FlowPortKind.input,
      ),
    ],
  );

  // Connect nodes via an edge with arrowheads
  final edge = FlowEdge(
    id: const FlowId('edge_1'),
    sourceNodeId: startNode.id,
    sourcePortName: 'out',
    targetNodeId: endNode.id,
    targetPortName: 'in',
    targetArrow: FlowArrowHead.triangle,
  );

  // Assemble into a document
  final document = FlowDocument(
    id: const FlowId('doc_1'),
    name: 'Order Workflow',
    pages: [
      FlowPage(
        id: const FlowId('page_1'),
        name: 'Main Page',
        nodes: {startNode.id: startNode, endNode.id: endNode},
        edges: {edge.id: edge},
      ),
    ],
  );
}
```

---

### 2. Interactive Editing with `FlowController`

`FlowController` is the single reactive entry point for mutating documents with full undo/redo and transaction management:

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  final controller = FlowController.empty();

  // Listen to document and selection change events
  controller.events.listen((event) {
    if (event is DocumentChanged) {
      print('Document updated: ${event.document.name}');
    } else if (event is SelectionChanged) {
      print('Selected nodes: ${event.selection.nodeIds}');
    }
  });

  // Add nodes
  final taskNode = FlowNode(
    id: controller.nextId(),
    type: 'rectangle',
    rect: const FlowRect.fromLTWH(100, 100, 120, 60),
    label: const FlowLabel(text: 'Review Draft'),
  );
  controller.addNode(taskNode);

  // Move nodes with automatic command-merging for continuous drags
  controller.moveNodes([taskNode.id], const FlowPoint(50, 0));

  // Perform atomic transactions (grouped as one undo step)
  controller.beginTransaction();
  try {
    controller.setNodeStyle(
      taskNode.id,
      FlowStyle.defaults.copyWith(fillColor: const FlowColor(0xFFE3F2FD)),
    );
    controller.selectNode(taskNode.id);
  } finally {
    controller.commitTransaction();
  }

  // Undo and Redo
  if (controller.canUndo) controller.undo();
  if (controller.canRedo) controller.redo();
}
```

---

### 3. Automatic Graph Layout

`flow_core` includes 4 built-in layout engines implementing `FlowLayoutEngine`.

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  final page = controller.activePage!;

  // 1. Run Sugiyama-style Layered Layout for DAGs / workflows
  const engine = LayeredLayout();
  final result = computeLayout(
    page,
    engine,
    direction: FlowLayoutDirection.leftToRight,
    spacing: const FlowLayoutSpacing(nodeSpacing: 40, layerSpacing: 80),
  );

  // 2. Apply computed node rectangles to controller within a transaction
  controller.beginTransaction();
  for (final entry in result.rects.entries) {
    controller.setNodeRect(entry.key, entry.value);
  }
  controller.commitTransaction();
}
```

#### Available Layout Engines:

| Engine | Description | Best For |
|---|---|---|
| `LayeredLayout` | Sugiyama-style layered layout with cycle breaking & crossing reduction | Workflow DAGs, state machines, flowcharts |
| `TreeLayout` | Reingold-Tilford / Walker style hierarchical tree layout | Organization charts, decision trees |
| `GridLayout` | Matrix distribution with custom column wrapping and cell gaps | Palette previews, unlinked node grids |
| `CircularLayout` | Radial placement around a center origin | Network topologies, circular workflows |

---

### 4. Edge Routing

Calculate edge connection paths between anchors using pluggable routing algorithms:

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  const router = OrthogonalRouter();

  final path = router.route(
    source: const FlowAnchor(
      point: FlowPoint(100, 50),
      side: FlowPortSide.right,
    ),
    target: const FlowAnchor(
      point: FlowPoint(300, 250),
      side: FlowPortSide.left,
    ),
    context: const FlowRoutingContext(),
  );

  print('Computed waypoints: ${path.points}');
}
```

- **`StraightRouter`**: Direct point-to-point linear path.
- **`BezierRouter`**: Smooth cubic Bézier spline with directional tangent control.
- **`OrthogonalRouter`**: Manhattan-style routing with 90° bends, obstacle margins, and waypoint honoring.

---

### 5. Spatial Indexing & Hit Testing

Query nodes at 60 FPS using the 2D Quadtree and perform sub-pixel hit testing:

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  // 1. 2D Quadtree for viewport culling and spatial range queries
  final quadtree = FlowQuadtree<FlowNode>(
    bounds: const FlowRect.fromLTWH(0, 0, 5000, 5000),
  );

  for (final node in document.firstPage!.nodes.values) {
    quadtree.insert(node, node.rect);
  }

  // Fast viewport query (O(log N))
  final visibleNodes = quadtree.query(
    const FlowRect.fromLTWH(0, 0, 800, 600),
  );

  // 2. Tolerance-aware Hit Testing
  final hitTester = FlowHitTester(
    page: document.firstPage!,
    tolerance: 6.0,
    portRadius: 8.0,
  );

  final result = hitTester.hitTest(const FlowPoint(120, 110));
  if (result.topPort != null) {
    print('Port clicked: ${result.topPort!.portName}');
  } else if (result.topNode != null) {
    print('Node clicked: ${result.topNode!.id}');
  } else if (result.topEdge != null) {
    print('Edge clicked: ${result.topEdge!.id}');
  }
}
```

---

### 6. Diagram Format Interoperability

Seamlessly convert between popular diagram formats and `FlowDocument`:

```dart
import 'package:flow_core/flow_core.dart';

void main() async {
  const mermaidInput = '''
flowchart TD
    A[Start] --> B{Valid?}
    B -->|Yes| C[Process]
    B -->|No| D[Reject]
''';

  // 1. Parse Mermaid into intermediate FlowGraph IR
  const mermaidFormat = MermaidFlowchartFormat();
  final graph = await mermaidFormat.parse(mermaidInput);

  // 2. Convert FlowGraph to a fully laid-out FlowDocument
  final converter = const FlowGraphConverter();
  final document = converter.toDocument(graph, runLayout: true);

  // 3. Export FlowDocument to Graphviz DOT
  final graphFromDoc = documentToFlowGraph(document);
  const dotFormat = GraphvizDotFormat();
  final dotOutput = await dotFormat.emit(graphFromDoc);

  // 4. Export to draw.io (diagrams.net) XML
  const drawioFormat = DrawioXmlFormat();
  final drawioXml = await drawioFormat.emit(graphFromDoc);
}
```

#### Supported Formats:

| Format | Extensions | Read | Write | Notes |
|---|---|:---:|:---:|---|
| **Mermaid Flowchart** | `.mmd`, `.mermaid` | ✅ | ✅ | Supports `flowchart`/`graph`, subgraphs, shapes (`[]`, `()`, `{}`, `[//]`, etc.), labels, and edge kinds |
| **Graphviz DOT** | `.dot`, `.gv` | ✅ | ✅ | Supports directed/undirected graphs, subgraphs, attributes, port specifiers |
| **draw.io XML** | `.drawio`, `.xml` | ✅ | ✅ | Parses and serializes uncompressed `mxGraphModel` diagrams |

---

### 7. Lossless JSON Serialization

`FlowJsonCodec` provides deterministic, round-trip lossless JSON encoding with compact defaults and schema migrations:

```dart
import 'package:flow_core/flow_core.dart';

void main() {
  const codec = FlowJsonCodec(pretty: true);

  // Encode document to JSON string
  final jsonString = codec.encode(document);

  // Decode JSON string back to FlowDocument
  final restoredDoc = codec.decode(jsonString);

  assert(restoredDoc.id == document.id);
}
```

For schema version details, consult [docs/schema.md](docs/schema.md).

---

## Running Tests

Run the full test suite and linter:

```bash
# Run all unit and integration tests (210+ tests)
dart test

# Run benchmarks
dart test -t benchmark

# Run static analysis
dart analyze
```

---

## Contributing

Contributions are welcome! Please ensure:
1. All changes pass `dart analyze` with zero warnings.
2. New features or bug fixes include accompanying tests in `test/`.
3. Code adheres to standard Dart formatting (`dart format .`).

---

## License

This project is licensed under the [MIT License](LICENSE).

/// Real-world Graphviz DOT examples.
library;

class DotFixture {
  const DotFixture(this.name, this.source);
  final String name;
  final String source;
}

const simpleDigraph = DotFixture('simple_digraph', '''
digraph G {
  rankdir=LR;
  A [shape=box, label="Start"];
  B [shape=ellipse, label="End"];
  A -> B [label="next"];
}
''');

const clustered = DotFixture('clustered', '''
digraph Flow {
  rankdir=TB;
  subgraph cluster_exit {
    label="Exit";
    style=filled;
    color=lightgrey;
    E [label="Exit case"];
    EV [label="Exit case versions"];
  }
  subgraph cluster_finance {
    label="Finance";
    F [label="Final pay"];
    FV [label="Final pay versions"];
  }
  E -> EV;
  E -> F;
  EV -> FV;
  F -> FV;
}
''');

const undirectedGraph = DotFixture('undirected', '''
graph G {
  A -- B;
  B -- C;
  A -- C;
  C -- D;
}
''');

const chained = DotFixture('chained', '''
digraph G {
  rankdir=LR;
  A -> B -> C -> D -> E;
}
''');

const nodeDefaults = DotFixture('node_defaults', '''
digraph G {
  node [shape=box, style=filled, fillcolor="#dae8fc"];
  edge [style=dashed, color="#666666"];
  A -> B;
  B -> C;
  C -> A;
}
''');

const ports = DotFixture('ports', '''
digraph G {
  A:out -> B:in;
  A:out -> C:in;
  B:out -> D:in;
  C:out -> D:in;
}
''');

const nestedClusters = DotFixture('nested_clusters', '''
digraph G {
  subgraph cluster_outer {
    label="Outer";
    subgraph cluster_inner {
      label="Inner";
      A -> B;
    }
    B -> C;
  }
}
''');

const styledEdges = DotFixture('styled_edges', '''
digraph G {
  A -> B [label="normal"];
  A -> C [label="dashed", style=dashed];
  A -> D [label="thick", penwidth=3];
  A -> E [label="none", arrowhead=none];
}
''');

const quotedIds = DotFixture('quoted_ids', '''
digraph G {
  "node one" -> "node two";
  "node two" -> "node-three";
}
''');

const withComments = DotFixture('with_comments', '''
// leading comment
digraph G {
  /* block comment */
  A -> B; // trailing
  # hash comment
  B -> C;
}
''');

const allFixtures = <DotFixture>[
  simpleDigraph,
  clustered,
  undirectedGraph,
  chained,
  nodeDefaults,
  ports,
  nestedClusters,
  styledEdges,
  quotedIds,
  withComments,
];
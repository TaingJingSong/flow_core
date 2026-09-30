/// Barrel export for test fixtures across formats (Graphviz DOT, draw.io, Mermaid).
library;

import 'dot_fixtures.dart' as dot;
import 'drawio_fixtures.dart' as drawio;
import 'mermaid_fixtures.dart' as mermaid;

export 'dot_fixtures.dart' hide allFixtures, styledEdges;
export 'drawio_fixtures.dart' hide allFixtures, shapes, styledEdges;
export 'mermaid_fixtures.dart' hide allFixtures, shapes;

// Disambiguated exports for fixtures with overlapping names:
const dotStyledEdges = dot.styledEdges;
const drawioStyledEdges = drawio.styledEdges;
const drawioShapes = drawio.shapes;
const mermaidShapes = mermaid.shapes;

const dotAllFixtures = dot.allFixtures;
const drawioAllFixtures = drawio.allFixtures;
const mermaidAllFixtures = mermaid.allFixtures;

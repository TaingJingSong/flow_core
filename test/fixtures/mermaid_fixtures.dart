/// Real-world Mermaid examples used by the round-trip and pipeline tests.
library;

class MermaidFixture {
  const MermaidFixture(this.name, this.source);
  final String name;
  final String source;
}

const exitFlow = MermaidFixture('exit_flow', '''
flowchart TD
    E["Exit case"] --> EV["Exit case versions"]
    E --> F["Final pay"]
    E --> D["Documents"]
    F --> FV["Final pay versions"]
    EV --> FV
    FV --> I["Final pay items"]
    FV --> A["Approval tasks"]
    FV --> P["Payments"]
''');

const shapes = MermaidFixture('shapes', '''
flowchart LR
    A[Rectangle]
    B(Rounded)
    C((Circle))
    D{Diamond}
    E{{Hexagon}}
    F[[Subroutine]]
    G[(Cylinder)]
    H>Asymmetric]
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
''');

const decisionTree = MermaidFixture('decision_tree', '''
flowchart TD
    Start([Start]) --> Q1{Is it valid?}
    Q1 -->|Yes| Process[Process]
    Q1 -->|No| Reject[Reject]
    Process --> End([End])
    Reject --> End
''');

const subgraphs = MermaidFixture('subgraphs', '''
flowchart TB
    subgraph user[User Actions]
      Login[Login]
      Browse[Browse]
    end
    subgraph system[System]
      Auth[Authenticate]
      Load[Load Data]
    end
    Login --> Auth
    Browse --> Load
    Auth --> Home[Home]
    Load --> Home
''');

const dashedAndThick = MermaidFixture('dashed_thick', '''
flowchart LR
    A --> B
    B -.-> C
    C ==> D
    D --- E
''');

const longChain = MermaidFixture('long_chain', '''
flowchart TD
    A --> B --> C --> D --> E --> F --> G --> H --> I --> J
''');

const cycles = MermaidFixture('cycles', '''
flowchart TD
    A --> B
    B --> C
    C --> A
    C --> D
    D --> B
''');

const comments = MermaidFixture('comments', '''
%% This is a header comment
flowchart TD
    %% Start node
    A --> B
    %% This is another comment
    B --> C
''');

const singleNode = MermaidFixture('single_node', '''
flowchart TD
    OnlyNode["Just one"]
''');

const allFixtures = <MermaidFixture>[
  exitFlow,
  shapes,
  decisionTree,
  subgraphs,
  dashedAndThick,
  longChain,
  cycles,
  comments,
  singleNode,
];
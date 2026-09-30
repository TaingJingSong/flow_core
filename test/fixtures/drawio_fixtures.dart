/// Real-world draw.io / diagrams.net examples.
library;

class DrawioFixture {
  const DrawioFixture(this.name, this.source);
  final String name;
  final String source;
}

const simple = DrawioFixture('simple', '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="a" value="Start"
            style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
            vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="120" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="b" value="End"
            style="ellipse;whiteSpace=wrap;html=1;fillColor=#d5e8d4;"
            vertex="1" parent="1">
      <mxGeometry x="400" y="40" width="100" height="100" as="geometry"/>
    </mxCell>
    <mxCell id="e1" value="next"
            style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=classic;"
            edge="1" parent="1" source="a" target="b">
      <mxGeometry relative="1" as="geometry">
        <Array as="points">
          <mxPoint x="260" y="70"/>
          <mxPoint x="260" y="90"/>
        </Array>
      </mxGeometry>
    </mxCell>
  </root>
</mxGraphModel>
''');

const withGroup = DrawioFixture('with_group', '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="g1" value="Exit Stage" style="group" vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="400" height="200" as="geometry"/>
    </mxCell>
    <mxCell id="n1" value="Exit case"
            style="rounded=1;whiteSpace=wrap;html=1;"
            vertex="1" parent="g1">
      <mxGeometry x="60" y="80" width="120" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="n2" value="Versions"
            style="rounded=1;whiteSpace=wrap;html=1;"
            vertex="1" parent="g1">
      <mxGeometry x="260" y="80" width="120" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;html=1;endArrow=classic;"
            edge="1" parent="1" source="n1" target="n2">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''');

const shapes = DrawioFixture('shapes', '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="rect" value="Rect" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="round" value="Round" style="rounded=1;" vertex="1" parent="1">
      <mxGeometry x="200" y="40" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="ell" value="Ellipse" style="ellipse;" vertex="1" parent="1">
      <mxGeometry x="360" y="40" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="dia" value="Diamond" style="rhombus;" vertex="1" parent="1">
      <mxGeometry x="40" y="140" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="hex" value="Hex" style="shape=hexagon;" vertex="1" parent="1">
      <mxGeometry x="200" y="140" width="100" height="50" as="geometry"/>
    </mxCell>
    <mxCell id="cyl" value="Cylinder" style="shape=cylinder3;" vertex="1" parent="1">
      <mxGeometry x="360" y="140" width="100" height="50" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''');

const styledEdges = DrawioFixture('styled_edges', '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="a" value="A" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="80" height="40" as="geometry"/>
    </mxCell>
    <mxCell id="b" value="B" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="40" y="140" width="80" height="40" as="geometry"/>
    </mxCell>
    <mxCell id="c" value="C" style="rounded=0;" vertex="1" parent="1">
      <mxGeometry x="40" y="240" width="80" height="40" as="geometry"/>
    </mxCell>
    <mxCell id="e1" style="dashed=1;endArrow=classic;" edge="1" parent="1" source="a" target="b">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
    <mxCell id="e2" style="strokeWidth=3;endArrow=open;" edge="1" parent="1" source="b" target="c">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
''');

const emptyGraph = DrawioFixture('empty_graph', '''
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
  </root>
</mxGraphModel>
''');

const allFixtures = <DrawioFixture>[
  simple,
  withGroup,
  shapes,
  styledEdges,
  emptyGraph,
];
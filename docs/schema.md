# flow_core JSON schema

**Schema version:** `1`
**Status:** Stable
**Applies to:** `FlowJsonCodec.encode` / `FlowJsonCodec.decode`

This document is normative. When it and the code disagree, one of them is a bug.

---

## 1. Overview

A flow document is a JSON object with:

- a `schemaVersion` integer,
- document identity and metadata,
- an ordered list of `pages`,
- each page containing `layers`, `groups`, `nodes`, and `edges`.

Every entity has a stable string `id`. IDs are unique within their owning scope:

- `FlowId` of a document is unique across the file.
- Page IDs are unique within a document.
- Node, edge, and group IDs are unique within a page.
- Layer IDs are unique within a page.
- Port names are unique within a node.

The wire format is designed to be:

- **Round-trip lossless.** `decode(encode(doc)) == doc`.
- **Diffable.** Stable key order, no random spacing, `pretty: true` supported.
- **Forward-compatible.** Unknown enum values decode to a documented default; unknown keys are ignored on decode but preserved inside `data` and `custom` maps.
- **Migration-safe.** `schemaVersion` is required. Older documents migrate; newer documents throw.

---

## 2. Conventions

### 2.1 Key naming

All keys are **camelCase** and match the Dart field names.

### 2.2 Omitted vs null

Optional fields with a `null` value in the model are **omitted** from the wire format. Missing key ≡ `null` on decode.

Fields with non-null defaults (`visible: true`, `zIndex: 0`, `opacity: 1.0`) are also omitted when they equal the default, to keep files small and diffs clean.

### 2.3 Enums

Enums encode as the Dart `.name` string, e.g. `"filledArrow"`, `"orthogonal"`, `"sequenceFlow"`.

On decode, an unknown value falls back to the documented default for that field. The default is listed in each section below.

### 2.4 Colors

Colors encode as `"#AARRGGBB"` — eight hex digits, uppercase, with a leading `#`.

On decode:

- `"#RRGGBB"` → alpha is `FF`.
- `"#AARRGGBB"` → used as-is.
- Any other shape → falls back to the caller's default.

Examples:

| Model value | Encoded |
|---|---|
| `FlowColor(0xFFAABBCC)` | `"#FFAABBCC"` |
| `FlowColor.fromARGB(0x80, 0x12, 0x34, 0x56)` | `"#80123456"` |
| `FlowColor(0x00000000)` | `"#00000000"` |

### 2.5 Dates

Dates encode as ISO-8601 strings in UTC, e.g. `"2025-01-01T00:00:00.000Z"`.

On decode, any string accepted by `DateTime.tryParse` is used; parse failures become `null`.

### 2.6 Numbers

All numbers are JSON numbers. Coordinates, sizes, and radii are `double`. Counters like `zIndex` are `int`.

NaN, `Infinity`, and `-Infinity` are not representable and are not permitted. Producers must sanitize before encoding.

### 2.7 Collections

Entities keyed by ID in the model (`Map<FlowId, T>`) encode as **ordered JSON arrays** with `id` inside each entry. This keeps the format diffable and human-readable.

Order rules:

- `pages`: model order.
- `layers`: ascending `zIndex`, then insertion order.
- `groups`, `nodes`, `edges`: model map insertion order.

Consumers must not rely on array order for semantics, only for rendering when `zIndex` is tied.

### 2.8 Unknown keys

Unknown keys at any level are ignored during decode. If you need to store custom data, use the `data` (per node/edge/group) or `custom` (per document) maps.

---

## 3. Top-level object

```json
{
  "schemaVersion": 1,
  "id": "doc",
  "name": "Untitled",
  "metadata": { },
  "pages": [ ]
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `schemaVersion` | int | yes | — | Required. See §11. |
| `id` | string | yes | — | Document ID. |
| `name` | string | no | `"Untitled"` | Human-facing name. |
| `metadata` | object | no | `{}` | See §4. |
| `pages` | array | no | `[]` | See §5. |

---

## 4. `metadata`

```json
{
  "title": "Exit Flow",
  "description": "Final pay lifecycle",
  "author": "Pocket",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-02T10:30:00.000Z",
  "tags": ["flow", "hr"],
  "custom": { "source": "mermaid" }
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `title` | string | no | `null` | Omitted when null. |
| `description` | string | no | `null` | Omitted when null. |
| `author` | string | no | `null` | Omitted when null. |
| `createdAt` | string (ISO-8601) | no | `null` | Omitted when null. |
| `updatedAt` | string (ISO-8601) | no | `null` | Omitted when null. |
| `tags` | array of strings | no | `[]` | Omitted when empty. |
| `custom` | object | no | `{}` | Arbitrary JSON. Omitted when empty. |

`custom` values may be any JSON value: string, number, bool, null, array, or object. It is preserved verbatim.

---

## 5. `page`

```json
{
  "id": "page_1",
  "name": "Main",
  "bounds": { "left": 0, "top": 0, "width": 2000, "height": 2000 },
  "meta": { "zoom": "1.0" },
  "layers": [ ],
  "groups": [ ],
  "nodes": [ ],
  "edges": [ ]
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | yes | — | Page ID. |
| `name` | string | no | `"Page"` | Human-facing name. |
| `bounds` | rect | no | `null` | Optional canvas size hint. Omitted when null. |
| `meta` | object of strings | no | `{}` | Omitted when empty. |
| `layers` | array of layer | no | `[]` | See §6. |
| `groups` | array of group | no | `[]` | See §7. Omitted when empty. |
| `nodes` | array of node | no | `[]` | See §8. Omitted when empty. |
| `edges` | array of edge | no | `[]` | See §9. Omitted when empty. |

A page with no layers is technically valid but discouraged; tooling should add a `default` layer on first edit.

---

## 6. `layer`

```json
{
  "id": "default",
  "name": "Default",
  "visible": true,
  "locked": false,
  "zIndex": 0,
  "opacity": 1.0
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | yes | — | Layer ID. |
| `name` | string | yes | `"Layer"` | Human-facing name. |
| `visible` | bool | no | `true` | Omitted when true. |
| `locked` | bool | no | `false` | Omitted when false. |
| `zIndex` | int | no | `0` | Omitted when 0. |
| `opacity` | double | no | `1.0` | Range `[0.0, 1.0]`. Omitted when 1.0. |

Nodes, groups, and edges reference their layer via `layerId`. When `layerId` is omitted, the entity belongs to the page's default layer.

---

## 7. `group`

```json
{
  "id": "g1",
  "rect": { "left": 180, "top": -20, "width": 220, "height": 220 },
  "label": { "text": "Exit" },
  "childNodeIds": ["n_exit", "n_versions"],
  "childGroupIds": [],
  "style": { "cornerRadius": 8, "strokeDashPattern": [4, 2] },
  "collapsed": false,
  "parentGroupId": null,
  "layerId": "default",
  "namespace": null,
  "data": {},
  "meta": {},
  "zIndex": 0,
  "locked": false,
  "visible": true
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | yes | — | Group ID. |
| `rect` | rect | yes | — | See §10. |
| `label` | label | no | `null` | See §10. |
| `childNodeIds` | array of strings | no | `[]` | Omitted when empty. |
| `childGroupIds` | array of strings | no | `[]` | Omitted when empty. |
| `style` | style | no | defaults | See §10. |
| `collapsed` | bool | no | `false` | Omitted when false. |
| `parentGroupId` | string | no | `null` | Omitted when null. |
| `layerId` | string | no | `null` | Omitted when null. |
| `namespace` | string | no | `null` | Omitted when null. |
| `data` | object | no | `{}` | Arbitrary JSON. Omitted when empty. |
| `meta` | object of strings | no | `{}` | Omitted when empty. |
| `zIndex` | int | no | `0` | Omitted when 0. |
| `locked` | bool | no | `false` | Omitted when false. |
| `visible` | bool | no | `true` | Omitted when true. |

**Membership invariant.** A group's children appear in both `childNodeIds`/`childGroupIds` and each child's `parentGroupId`. Producers must keep both directions in sync. Consumers should treat `childNodeIds` as authoritative if they disagree.

**Cycle invariant.** Groups must not form cycles. Self-referencing groups are invalid.

---

## 8. `node`

```json
{
  "id": "n_exit",
  "type": "rectangle",
  "rect": { "left": 200, "top": 0, "width": 120, "height": 60 },
  "style": {
    "fillColor": "#FFFFFFFF",
    "strokeColor": "#FF000000",
    "strokeWidth": 1.0,
    "cornerRadius": 4.0,
    "opacity": 1.0
  },
  "label": { "text": "Exit case", "position": "center" },
  "ports": [
    { "name": "in",  "side": "left",  "kind": "input"  },
    { "name": "out", "side": "right", "kind": "output" }
  ],
  "data": { "payload": { "size": 3 } },
  "tags": ["entry"],
  "meta": { "stereotype": "start" },
  "parentGroupId": "g1",
  "layerId": "default",
  "namespace": null,
  "zIndex": 0,
  "locked": false,
  "visible": true,
  "rotation": 0.0
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | yes | — | Node ID. |
| `type` | string | yes | `"rectangle"` | Semantic type. See §8.1. |
| `rect` | rect | yes | — | Position and size. See §10. |
| `style` | style | no | defaults | See §10. |
| `label` | label | no | `null` | See §10. |
| `ports` | array of port | no | `[]` | See §8.2. Omitted when empty. |
| `data` | object | no | `{}` | Arbitrary JSON. Omitted when empty. |
| `tags` | array of strings | no | `[]` | Omitted when empty. |
| `meta` | object of strings | no | `{}` | Omitted when empty. |
| `parentGroupId` | string | no | `null` | Omitted when null. |
| `layerId` | string | no | `null` | Omitted when null. |
| `namespace` | string | no | `null` | Omitted when null. |
| `zIndex` | int | no | `0` | Omitted when 0. |
| `locked` | bool | no | `false` | Omitted when false. |
| `visible` | bool | no | `true` | Omitted when true. |
| `rotation` | double | no | `0.0` | Radians, clockwise. Omitted when 0.0. |

### 8.1 Node `type` values

`type` is a free-form string. Renderers map it to a shape. The core ships with these recommendations, and format parsers must map their constructs onto them:

| Type | Visual |
|---|---|
| `rectangle` | Axis-aligned rectangle. |
| `rounded` | Rectangle with corner radius. |
| `circle` | Circle. |
| `ellipse` | Ellipse. |
| `diamond` | Diamond / decision. |
| `hexagon` | Hexagon. |
| `parallelogram` | Slanted rectangle. |
| `cylinder` | Database / storage. |
| `subroutine` | Rectangle with double side lines. |
| `asymmetric` | Flag / callout. |
| `note` | Sticky note. |
| `state` | Rounded state box. |
| `class` | UML class box. |
| `entity` | ER entity. |
| `actor` | UML actor. |
| `start` | Start event. |
| `end` | End event. |
| `task` | BPMN task. |
| `gateway` | BPMN gateway. |
| `custom` | Renderer-defined; use `data`. |

### 8.2 `port`

```json
{
  "name": "out",
  "side": "right",
  "kind": "output",
  "position": 0.5,
  "isConnectable": true,
  "label": null
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `name` | string | yes | — | Unique within the node. |
| `side` | enum | no | `"center"` | One of `top`, `right`, `bottom`, `left`, `center`. |
| `kind` | enum | no | `"bidirectional"` | One of `input`, `output`, `bidirectional`. |
| `position` | double | no | `0.5` | Along the side, `[0.0, 1.0]`. Ignored for `center`. |
| `isConnectable` | bool | no | `true` | Omitted when true. |
| `label` | label | no | `null` | See §10. |

---

## 9. `edge`

```json
{
  "id": "e1",
  "source": "n_exit",
  "target": "n_versions",
  "sourcePort": "out",
  "targetPort": null,
  "kind": "flow",
  "routing": "orthogonal",
  "waypoints": [ { "x": 380, "y": 30 }, { "x": 380, "y": 130 } ],
  "sourceArrow": "none",
  "targetArrow": "filledArrow",
  "style": { "strokeColor": "#FF000000", "strokeWidth": 1.5 },
  "label": { "text": "yes" },
  "data": {},
  "meta": { "weight": "1" },
  "namespace": null,
  "zIndex": 0,
  "locked": false,
  "visible": true
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | yes | — | Edge ID. |
| `source` | string | yes | — | Source node ID. |
| `target` | string | yes | — | Target node ID. |
| `sourcePort` | string | no | `null` | Port name on source. `null` = node center. |
| `targetPort` | string | no | `null` | Port name on target. `null` = node center. |
| `kind` | enum | no | `"flow"` | See §9.1. |
| `routing` | enum | no | `"straight"` | See §9.2. |
| `waypoints` | array of point | no | `[]` | See §10. Omitted when empty. |
| `sourceArrow` | enum | no | `"none"` | See §9.3. |
| `targetArrow` | enum | no | `"filledArrow"` | See §9.3. |
| `style` | style | no | defaults | See §10. |
| `label` | label | no | `null` | See §10. |
| `data` | object | no | `{}` | Arbitrary JSON. Omitted when empty. |
| `meta` | object of strings | no | `{}` | Omitted when empty. |
| `namespace` | string | no | `null` | Omitted when null. |
| `zIndex` | int | no | `0` | Omitted when 0. |
| `locked` | bool | no | `false` | Omitted when false. |
| `visible` | bool | no | `true` | Omitted when true. |

**Referential integrity.** `source` and `target` must reference existing nodes on the same page. `sourcePort` and `targetPort`, when present, must name existing ports on the referenced nodes. Broken references are invalid; validators report them.

### 9.1 `kind` values

| Value | Meaning |
|---|---|
| `flow` | Generic flowchart arrow. **Default.** |
| `association` | UML association. |
| `inheritance` | UML extends / implements. |
| `composition` | UML composition. |
| `aggregation` | UML aggregation. |
| `dependency` | UML dependency. |
| `transition` | State machine transition. |
| `message` | Sequence diagram message. |
| `sequenceFlow` | BPMN sequence flow. |
| `messageFlow` | BPMN message flow. |
| `link` | Undirected link. |
| `custom` | Renderer-defined; see `meta['kind']`. |

Unknown values decode to `flow`.

### 9.2 `routing` values

| Value | Meaning |
|---|---|
| `straight` | Straight line from source to target. **Default.** |
| `orthogonal` | Manhattan path. |
| `bezier` | Cubic bezier. |
| `quadratic` | Quadratic curve. |
| `obstacleAvoiding` | Orthogonal with obstacle avoidance. |
| `custom` | Path taken verbatim from `data['path']`. |

Unknown values decode to `straight`.

When `routing` is `custom`, the renderer reads the exact geometry from `data['path']`. The schema does not prescribe its shape; each renderer documents its own.

### 9.3 `arrow` values

Used for `sourceArrow` and `targetArrow`.

| Value | Meaning |
|---|---|
| `none` | No mark. |
| `arrow` | Open arrow head. |
| `filledArrow` | Filled triangle. |
| `hollowArrow` | Hollow triangle. |
| `diamond` | Open diamond. |
| `filledDiamond` | Filled diamond. |
| `circle` | Open circle. |
| `filledCircle` | Filled circle. |
| `square` | Open square. |
| `filledSquare` | Filled square. |
| `cross` | Cross mark. |
| `bar` | Bar / tick. |

Unknown values decode to `none` for `sourceArrow` and `filledArrow` for `targetArrow`.

---

## 10. Shared structures

### 10.1 `point`

```json
{ "x": 10.0, "y": 20.0 }
```

| Field | Type | Required | Default |
|---|---|---|---|
| `x` | double | yes | `0.0` |
| `y` | double | yes | `0.0` |

### 10.2 `size`

```json
{ "width": 100.0, "height": 40.0 }
```

| Field | Type | Required | Default |
|---|---|---|---|
| `width` | double | yes | `0.0` |
| `height` | double | yes | `0.0` |

### 10.3 `rect`

```json
{ "left": 0.0, "top": 0.0, "width": 100.0, "height": 40.0 }
```

| Field | Type | Required | Default |
|---|---|---|---|
| `left` | double | yes | `0.0` |
| `top` | double | yes | `0.0` |
| `width` | double | yes | `0.0` |
| `height` | double | yes | `0.0` |

Origin is top-left. `y` grows downward. `left` and `top` are the top-left corner; `width` and `height` are non-negative.

### 10.4 `style`

```json
{
  "fillColor": "#FFFFFFFF",
  "strokeColor": "#FF000000",
  "strokeWidth": 1.0,
  "strokeDashPattern": [4.0, 2.0],
  "cornerRadius": 4.0,
  "opacity": 1.0,
  "shadow": {
    "color": "#33000000",
    "offset": { "x": 0, "y": 2 },
    "blurRadius": 4.0,
    "spreadRadius": 0.0
  },
  "textStyle": {
    "fontFamily": "Inter",
    "fontSize": 14.0,
    "fontWeight": 400,
    "fontStyle": "normal",
    "color": "#FF000000",
    "letterSpacing": 0.0,
    "lineHeight": 1.2,
    "decoration": "none"
  }
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `fillColor` | color | no | `null` | Omitted when null. |
| `strokeColor` | color | no | `null` | Omitted when null. |
| `strokeWidth` | double | no | `1.0` | Omitted when 1.0. |
| `strokeDashPattern` | array of doubles | no | `null` | Alternating on/off lengths. Omitted when null. |
| `cornerRadius` | double | no | `0.0` | Omitted when 0.0. |
| `opacity` | double | no | `1.0` | Range `[0.0, 1.0]`. Omitted when 1.0. |
| `shadow` | shadow | no | `null` | Omitted when null. |
| `textStyle` | text style | no | `null` | Default for child labels. |

Any field may be `null`, meaning "inherit from parent" or "renderer default".

### 10.5 `shadow`

| Field | Type | Required | Default |
|---|---|---|---|
| `color` | color | no | `"#33000000"` |
| `offset` | point | no | `{ "x": 0, "y": 0 }` |
| `blurRadius` | double | no | `0.0` |
| `spreadRadius` | double | no | `0.0` |

### 10.6 `textStyle`

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `fontFamily` | string | no | `null` | Omitted when null. |
| `fontSize` | double | no | `14.0` | |
| `fontWeight` | int | no | `400` | `100`–`900` in steps of `100`. |
| `fontStyle` | enum | no | `"normal"` | `normal` or `italic`. |
| `color` | color | no | `"#FF000000"` | |
| `letterSpacing` | double | no | `null` | Omitted when null. |
| `lineHeight` | double | no | `null` | Multiplier of `fontSize`. Omitted when null. |
| `decoration` | enum | no | `"none"` | `none`, `underline`, `overline`, `lineThrough`. |

Unknown enum values decode to the defaults shown.

### 10.7 `label`

```json
{
  "text": "Exit case",
  "style": { "fontSize": 14.0, "fontWeight": 400 },
  "position": "center",
  "alignment": "center",
  "offset": { "x": 0.0, "y": 0.0 },
  "maxWidth": 200.0,
  "rotation": 0.0
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `text` | string | no | `""` | |
| `style` | text style | no | `null` | Omitted when null. |
| `position` | enum | no | `"center"` | See below. |
| `alignment` | enum | no | `"center"` | `left`, `center`, `right`, `justify`. |
| `offset` | point | no | `{ "x": 0, "y": 0 }` | Omitted when zero. |
| `maxWidth` | double | no | `null` | Omitted when null. |
| `rotation` | double | no | `0.0` | Radians. Omitted when 0.0. |

`position` values: `center`, `top`, `bottom`, `left`, `right`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `start`, `end`, `custom`.

Unknown values decode to `center`.

---

## 11. Versioning and migrations

### 11.1 Current version

`schemaVersion` for this document is **1**.

### 11.2 Rules for producers

- Always write `schemaVersion`.
- Always write the current version, never an older one.
- Bump the version only for **breaking** changes: renaming keys, changing types, removing required fields.
- Non-breaking additions (new optional fields, new enum values) do **not** require a bump.

### 11.3 Rules for consumers

- A document with `schemaVersion` less than the current version must be migrated via `FlowMigrations`.
- A document with `schemaVersion` greater than the current version must throw `FlowMigrationException`.
- A document with no `schemaVersion` must throw `FlowMigrationException`.

### 11.4 Migration path

When bumping the version, add a transformation in `FlowMigrations.migrate` that upgrades the previous version into the next. Chain them so any supported old file can be read:

```
v1 → v2 → v3 → ... → current
```

Each migration step must be:

- **Pure.** Same input → same output.
- **Total.** Must never throw on well-formed prior-version input.
- **Preserving.** Must not drop fields it doesn't understand.

### 11.5 Future changes under consideration

The following changes would require a version bump:

- Replacing `rect` with per-shape geometry.
- Renaming `data` or `custom`.
- Moving `metadata` under a nested object.
- Changing the enum defaults documented above.

Non-breaking additions that will **not** bump the version:

- New node `type` values.
- New `data` payloads.
- New `meta` keys.
- New optional fields on existing objects.

---

## 12. Validation rules

A conformant `FlowDocument` satisfies the following. Validators report violations as diagnostics, not exceptions.

### 12.1 Document

- `schemaVersion` present and equal to a supported version.

### 12.2 Page

- `id` unique within the document.
- `layers` contains at least one entry.
- Every `node`, `edge`, and `group` has `layerId` that names an existing layer, or `null`.

### 12.3 Node

- `id` unique within the page.
- `rect.width` and `rect.height` are non-negative.
- `ports` names are unique within the node.
- If `parentGroupId` is present, it names a group on the same page.
- If `parentGroupId` is present, the group's `childNodeIds` contains this node's `id`.

### 12.4 Edge

- `id` unique within the page.
- `source` and `target` name existing nodes on the same page.
- If `sourcePort` is present, the source node declares a port with that name.
- If `targetPort` is present, the target node declares a port with that name.
- `source` and `target` are not equal (self-loops are permitted only when a renderer opts in).

### 12.5 Group

- `id` unique within the page.
- `rect.width` and `rect.height` are non-negative.
- If `parentGroupId` is present, it names a group on the same page.
- No cycles through `parentGroupId` or `childGroupIds`.
- Every entry in `childNodeIds` names an existing node.
- Every entry in `childGroupIds` names an existing group.
- Membership is mirrored on the child's `parentGroupId`.

### 12.6 Layer

- `id` unique within the page.
- `opacity` in `[0.0, 1.0]`.

---

## 13. Complete example

```json
{
  "schemaVersion": 1,
  "id": "doc_1",
  "name": "Exit Flow",
  "metadata": {
    "title": "Exit Flow",
    "author": "Pocket",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "tags": ["flow"],
    "custom": { "source": "mermaid" }
  },
  "pages": [
    {
      "id": "page_1",
      "name": "Main",
      "meta": { "zoom": "1.0" },
      "layers": [
        { "id": "default", "name": "Default" }
      ],
      "groups": [
        {
          "id": "g1",
          "rect": { "left": 180, "top": -20, "width": 220, "height": 220 },
          "label": { "text": "Exit" },
          "childNodeIds": ["n_exit", "n_versions"],
          "style": { "cornerRadius": 8, "strokeDashPattern": [4, 2] }
        }
      ],
      "nodes": [
        {
          "id": "n_start",
          "type": "circle",
          "rect": { "left": 0, "top": 0, "width": 60, "height": 60 },
          "label": { "text": "Start" },
          "tags": ["entry"],
          "meta": { "stereotype": "start" }
        },
        {
          "id": "n_exit",
          "type": "rectangle",
          "rect": { "left": 200, "top": 0, "width": 120, "height": 60 },
          "label": { "text": "Exit case" },
          "ports": [
            { "name": "in", "side": "left", "kind": "input" },
            { "name": "out", "side": "right", "kind": "output" }
          ],
          "data": { "payload": { "size": 3, "tags": ["a", "b"] } },
          "parentGroupId": "g1"
        },
        {
          "id": "n_versions",
          "type": "rectangle",
          "rect": { "left": 200, "top": 100, "width": 160, "height": 60 },
          "label": { "text": "Exit case versions" },
          "parentGroupId": "g1"
        }
      ],
      "edges": [
        {
          "id": "e1",
          "source": "n_exit",
          "target": "n_versions",
          "sourcePort": "out",
          "kind": "flow",
          "routing": "orthogonal",
          "waypoints": [
            { "x": 380, "y": 30 },
            { "x": 380, "y": 130 }
          ],
          "sourceArrow": "none",
          "targetArrow": "filledArrow",
          "label": { "text": "yes" },
          "meta": { "weight": "1" }
        }
      ]
    }
  ]
}
```

---

## 14. Non-goals

The following are **not** part of the wire format and are handled elsewhere:

- Rendering. The format stores intent; renderers decide how to draw.
- Layout algorithms. Positions are always stored explicitly.
- Collaboration state (presence, cursors, CRDT metadata).
- Authentication and permissions.
- Binary assets. Large images or fonts belong in a separate store, referenced via `data['assetId']`.

---

*End of schema version 1.*
# Modularity metrics

These metrics are evidence that the code stays highly cohesive and loosely coupled (ADR-0005). They are computed per **logical component**, not per file, so they line up with the diagrams in the architecture documents, and at **two levels** (ADR-0010, ADR-0011):

| Level | Units | Declared in | Snapshots in |
|-------|-------|-------------|--------------|
| System | apps and libraries | [../components.json](../components.json) | `docs/architecture/metrics/` |
| App | the components inside one app | `apps/<app>/docs/architecture/components.json` | `apps/<app>/docs/architecture/metrics/` |

At system level any dependency from one app to another is a boundary violation. The definitions and thresholds below apply to both levels and exist only here.

## Metrics and thresholds

Changing a threshold requires an ADR.

| Metric | Definition | Level | Pass | Warn | Fail |
|--------|------------|-------|------|------|------|
| **Cyclomatic complexity (CC)** | Number of independent paths through a function (McCabe): 1 + the number of decision points | function | ≤ 10 | 11–15 | > 15 |
| **Efferent coupling (Ce)** | Number of *other components* this component depends on | component | ≤ 4 | 5–7 | > 7 |
| **Afferent coupling (Ca)** | Number of *other components* that depend on this component | component | (no limit, shown for context) | | |
| **Instability (I)** | Ce / (Ca + Ce); 0 = maximally stable, 1 = maximally unstable | component | | | |
| **Stable Dependencies violations** | Dependencies A → B where I(B) > I(A), i.e. depending on something less stable | edge | 0 | ≥ 1 | |
| **Dependency cycles** | Cycles in the component dependency graph | graph | 0 | | ≥ 1 |
| **Boundary violations** | Dependencies A → B where B is not in A's `mayDependOn` | edge | 0 | | ≥ 1 |
| **Relational cohesion (H)** | (R + 1) / N, where R = internal references between the component's N modules or types | component | 1.5–4.0 | outside that range | |
| **Abstractness (A)** and **distance (D)** | A = abstract types / all types; D = \|A + I − 1\| | component | D ≤ 0.5 | D > 0.5 | |

Notes:
- Ce and Ca count components, not files. Third-party libraries are reported separately (`externalDeps`) and do not count towards Ce.
- Abstractness and distance are reported only for languages with interfaces or traits (Go, Rust, TypeScript, Python ABCs or Protocols). Otherwise they are shown as `n/a`.
- A function between 11 and 15 needs a one-line justification in the code review. Anything over 15 must be split.

## Components files

`components.json` declares the logical components at each level. Boundary linters, the collector and the diagrams are all derived from them.

**System level** (root `docs/architecture/components.json`), validated and rendered by `tools/monorepo/system-map.sh`:

```json
{
  "components": [
    { "name": "assistant", "kind": "app", "responsibility": "Answers questions from processed manuals.",
      "paths": ["apps/assistant/**"], "mayDependOn": ["kg-model"], "reads": ["knowledge-graph"], "writes": [] },
    { "name": "kg-model", "kind": "lib", "responsibility": "Typed access to the knowledge graph.",
      "paths": ["libs/kg-model/**"], "mayDependOn": [], "public": ["libs/kg-model/src/kg_model/__init__.py"] }
  ],
  "datasets": [
    { "name": "knowledge-graph", "owner": "downloader", "description": "Glossary, ontology and graph.",
      "contract": "libs/contracts/knowledge-graph/", "location": "${SHARED_DATA_DIR}/knowledge-graph", "git": "ignore" }
  ]
}
```

`mayDependOn` (of an app or a library) may only name libraries (`kind: "lib"`). Only an app's `writes` may name a dataset it owns. A dataset's `git` is `commit` or `ignore`: whether `data/<dataset>/` goes into git; `ignore` needs a `/data/<dataset>/` line in `.gitignore` (ADR-0016).

**App level** (`apps/<app>/docs/architecture/components.json`), paths relative to the repo root:

```json
{
  "components": [
    {
      "name": "retrieval",
      "responsibility": "Fetches and normalises source documents.",
      "paths": ["apps/assistant/src/retrieval/**"],
      "mayDependOn": ["core"],
      "public": ["apps/assistant/src/retrieval/__init__.py"]
    }
  ]
}
```

`public` (optional) lists the entry points other components may import. Anything else counts as internal.

## Snapshot schema

Each language collector emits this JSON shape. Collectors for different languages are merged into one dated file at `history/YYYY-MM-DD.json`.

```json
{
  "date": "YYYY-MM-DD",
  "commit": "<git sha>",
  "languages": ["python"],
  "functions": {
    "count": 0, "ccAvg": 0.0, "ccMax": 0,
    "overWarn": [{ "file": "", "function": "", "cc": 0 }]
  },
  "components": [
    { "name": "", "ca": 0, "ce": 0, "instability": 0.0,
      "relationalCohesion": 0.0, "abstractness": null, "distance": null,
      "externalDeps": [] }
  ],
  "dependencies": [{ "from": "", "to": "", "count": 0 }],
  "cycles": [["a", "b", "a"]],
  "violations": [{ "kind": "boundary|cycle|sdp|cc", "detail": "" }],
  "result": "pass|warn|fail"
}
```

## Outputs

| File | Written by | Contents |
|------|------------|----------|
| `history/YYYY-MM-DD.json` (per level) | `/arch-metrics` | The full snapshot (a later snapshot on the same day replaces the earlier one) |
| [latest.md](latest.md) | `/arch-metrics` | Human-readable tables, the change since the previous snapshot, and the pass/warn/fail result |
| `architecture.md` §4 | `/arch-metrics` | Generated Mermaid coupling diagram: edges labelled with reference counts, nodes with Ca/Ce/I, boundary violations in red |

The per-language tools that produce these numbers are listed in [.claude/skills/add-language/playbook.md](../../../.claude/skills/add-language/playbook.md).

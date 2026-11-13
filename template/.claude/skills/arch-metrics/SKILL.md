---
name: arch-metrics
description: Compute cyclomatic complexity, afferent/efferent coupling, instability, cohesion, cycles and boundary violations, at system level (apps and shared components) and per app (its internal components); store dated snapshots; regenerate latest.md and the coupling diagrams. Use when the user runs /arch-metrics or asks for proof of modularity.
argument-hint: [system | <app> | all]   (default: all)
---

Scope: `$ARGUMENTS` (empty means `all`: the system level and every app).

1. Read `docs/architecture/metrics/README.md` (definitions, thresholds, schema, levels), `tools/quality/languages.json`, the root `docs/architecture/components.json`, and for each app in scope `apps/<app>/docs/architecture/components.json`.
2. Run `tools/monorepo/system-map.sh --check` first and report its findings; declared rules must hold before measured ones mean anything.
3. If no language is registered, report that there is nothing to measure and stop.
4. Run the metrics command of every registered language (`metrics` field in `languages.json`) once per level, with the matching `components.json`:
   - **System level:** the units are the apps and shared components. Any dependency from one app to another is a `boundary` violation, whatever `mayDependOn` says.
   - **App level:** the units are the components inside the app.
   Each run emits the snapshot schema. Merge languages per level: sum the counts per component, union the dependency edges, and recompute I, the cycles and the violations on the merged graph.
5. Write `history/<today>.json` (with the current commit sha) in `docs/architecture/metrics/` for the system and in `apps/<app>/docs/architecture/metrics/` for each app.
6. Regenerate each `latest.md`: the overall result; a component table (Ca, Ce, I, H, A, D, status); functions over the warn threshold; violations; and the **change since the previous snapshot** (new violations, CC max, Ce changes).
7. Regenerate the Mermaid block between `<!-- coupling:begin -->` and `<!-- coupling:end -->` in the matching `architecture.md`. Each node is labelled `name<br/>Ca·Ce·I`. Each edge is labelled with its reference count. Boundary violations and cycle edges are drawn red with `linkStyle`. Check that the measured edges match the declared ones, and report any drift.
8. Report the result per level to the user. If any is `fail`, list exactly what has to change. Never adjust a threshold to make the result pass.

# shared/__NAME__

__TEXT__

Shared code used by several apps (ADR-0010). Apps may import only the entry points listed in `public` for this component in the root [components.json](../../docs/architecture/components.json). Shared code never imports from an app.

Changes here can affect every app that lists `__NAME__` in its `mayDependOn`; check them all before changing a public entry point, and record breaking changes in a root ADR.

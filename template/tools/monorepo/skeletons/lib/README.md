# libs/__NAME__

__TEXT__

A library (ADR-0010, ADR-0015): source code that apps and other libraries import or call. Its users may import only the entry points listed in `public` for this library in the root [components.json](../../docs/architecture/components.json), and must list `__NAME__` in their `mayDependOn`. A library never imports from an app, and may use other libraries only if they are in its own `mayDependOn` (no cycles).

Changes here can affect every app and library that lists `__NAME__` in its `mayDependOn`; check them all before changing a public entry point, and record breaking changes in a root ADR.

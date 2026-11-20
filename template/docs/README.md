# Documentation

This is the **system level** of the documentation (ADR-0011). Each application documents itself in `apps/<app>/docs/`; start from the system map to find them.

1. **[architecture/architecture.md](architecture/architecture.md)**: the system today: which apps exist, what data and code they share, and the rules across them.
2. **[architecture/adr/](architecture/adr/README.md)**: why it looks that way, one system-wide decision at a time, oldest first. App decisions are in each app's `docs/architecture/adr/`.
3. **[architecture/metrics/](architecture/metrics/README.md)**: evidence that apps and components stay modular (complexity and coupling).
4. **[ideas/](ideas/README.md)** and **[specs/](specs/README.md)**: what we set out to build and how each piece was specified. The specs index covers both levels.
5. **[research/](research/README.md)**: reports, notes and brainstorming that informed the ideas.

[sessions/](sessions/README.md) holds the saved Claude Code sessions. [templates/](templates/) holds the templates the Claude Code skills use, for both levels.

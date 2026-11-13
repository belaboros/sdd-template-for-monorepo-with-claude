# __NAME__

__TEXT__

| | |
|---|---|
| **Kind** | application in the monorepo ([system architecture](../../docs/architecture/architecture.md)) |
| **Instructions for Claude** | [CLAUDE.md](CLAUDE.md) (adds to the root [CLAUDE.md](../../CLAUDE.md)) |
| **Architecture** | [docs/architecture/architecture.md](docs/architecture/architecture.md) · [ADRs](docs/architecture/adr/README.md) |
| **Specs** | [docs/specs/](docs/specs/README.md) (specs that concern this app only) |
| **Environment** | [.env.example](.env.example), layered over the root [.env.example](../../.env.example) |

## Run

```bash
cp apps/__NAME__/.env.example apps/__NAME__/.env    # only if this app needs its own variables
tools/env/with-env.sh __NAME__ --check
tools/env/with-env.sh __NAME__ -- <command>          # the run command is added by /plan
```

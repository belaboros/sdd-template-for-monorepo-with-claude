# Dataset contracts

One folder per shared dataset (ADR-0013, ADR-0015). Each holds a `README.md` with the dataset's **owner**, **format**, **schema** and **version** (plus location layout and guarantees), a `CHANGELOG.md`, and any machine-readable schemas.

- **One owner.** Only the owning app writes the dataset. Readers are declared with `reads` in [docs/architecture/components.json](../../docs/architecture/components.json).
- **Readers depend on the contract, not on the owner's code.** If a reader needs something the contract doesn't promise, change the contract first.
- **Versioned.** A breaking change is a major version, needs a root ADR, and lists what every reader has to change.
- **No code here.** Typed accessors or validators for a dataset are a library in `libs/<lib>/`, which may implement the contract.

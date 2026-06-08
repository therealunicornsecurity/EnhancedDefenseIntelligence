# Decision Log

Architectural decisions that shape this repo. Each is binding once accepted.

Format:

```
## DEC-NNN — <Title>
**Date**: YYYY-MM-DD
**Status**: proposed | accepted | rejected | superseded-by-DEC-NNN
**Context**: why the decision is needed
**Decision**: what was decided
**Consequences**: what follows from this
```

---

## DEC-001 — Adopt DEVKIT workspace conventions
**Date**: YYYY-MM-DD
**Status**: accepted
**Context**: This repo was scaffolded from DEVKIT, which encodes a specific TDD procedure, code review procedure, file structure, and naming convention. Whether the team adopts these as binding is itself a decision.
**Decision**: Adopt `RULES.md` as the law file. Every change goes through Procedure A (TDD). The Code Quality Review (Procedure B) is run before each release. File ownership tiers (Law/Scaffold/Merge/Local) govern what `edi.sh update` may overwrite.
**Consequences**: Code without a `docs/spec/` entry is technical debt. Files > 1000 lines must be split. Naming conventions are enforced at review. Local rule overrides go in `.claude/CLAUDE.local.md` (Tier 4) — never in `RULES.md` directly.

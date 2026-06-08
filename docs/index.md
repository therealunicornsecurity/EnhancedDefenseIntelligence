# Document Index

Documentation files only. Updated after every documentation modification.

Last updated: 2026-05-25

| File | Description | Lines |
|------|-------------|-------|
| `docs/index.md` | This file | — |
| `README.md` | Top-level kit explainer, quick start, "what's in the box" | — |
| `RULES.md` | Kit-self law (rendered from `templates/RULES.md` with `EDI`/`polyglot`) — the kit applies its own rules to itself | — |
| `Makefile` | Kit-self Makefile (rendered from `templates/Makefile`) | — |
| `VERSION` | Kit version (`MAJOR.MINOR.PATCH[-CODENAME]`) | 1 |
| `CHANGELOG.md` | Kit version history | — |
| `edi.sh` | Scaffolder: `init` (new repo), `update` (re-sync Tier-1), `comply` (rule check) | — |
| `templates/RULES.md` | The law file — 10 sections: structure, docs, TDD, review, security, Makefile, commits, AI rules, snapshot, ownership tiers | — |
| `templates/CLAUDE.md` | Per-repo `.claude/CLAUDE.md` template | — |
| `templates/Makefile` | Universal `build`/`test`/`nonreg`/`integration`/`lint`/`review`/`snapshot`/`clean` | — |
| `templates/VERSIONING.md` | `MAJOR.MINOR.PATCH[-CODENAME]` scheme, codename tiers, changelog format | — |
| `templates/codenames-example.yml` | Neutral starter pool (constellations) — replace with your own theme | — |
| `templates/CHANGELOG.template.md` | Initial `CHANGELOG.md` block, templated by `edi.sh init` | — |
| `templates/security/python.md` | Python-specific forbidden patterns + recommended idioms + secrets/secure-deletion guidance + tooling | — |
| `templates/security/c.md` | C-specific forbidden patterns + memory safety flags + `explicit_bzero`/secrets handling + tooling | — |
| `templates/security/rust.md` | Rust-specific forbidden patterns (`unwrap`/`unsafe` discipline/async) + `secrecy`/`zeroize` + tooling | — |
| `templates/security/go.md` | Go-specific forbidden patterns + concurrency rules + secrets handling + tooling | — |
| `templates/gitignore.python` | Python `.gitignore` | — |
| `templates/gitignore.go` | Go `.gitignore` | — |
| `templates/gitignore.typescript` | TypeScript `.gitignore` | — |
| `templates/gitignore.javascript` | JavaScript `.gitignore` | — |
| `templates/gitignore.cpp` | C++ `.gitignore` | — |
| `templates/gitignore.bash` | Bash `.gitignore` | — |
| `templates/gitignore.rust` | Rust `.gitignore` | — |
| `templates/gitignore.latex` | LaTeX `.gitignore` | — |
| `.claude/CLAUDE.md` | Kit's own meta-repo workspace law | — |
| `.claude/docs/index.md` | `.claude/` documentation index | — |
| `.claude/commands/tag.md` | `/tag` — version bump + CHANGELOG + git tag | — |
| `.claude/commands/freeze.md` | `/freeze` — snapshot under a codename | — |
| `.claude/commands/new_tool.md` | `/new_tool` — scaffold a new repo via edi.sh | — |
| `.claude/commands/procedure_a.md` | `/procedure_a` — TDD walkthrough | — |
| `.claude/commands/procedure_b.md` | `/procedure_b` — code review walkthrough | — |
| `.claude/skills/commit_format/SKILL.md` | `/commit_format` — `type(scope): description` reference | — |
| `.claude/skills/review/SKILL.md` | `/review` — structured code review | — |
| `.claude/skills/refactor/SKILL.md` | `/refactor` — systematic refactoring | — |
| `.claude/skills/test_gen/SKILL.md` | `/test_gen` — generate test suites | — |
| `.claude/skills/perf_benchmark/SKILL.md` | `/perf_benchmark` — before/after benchmark for OPTIMIZE | — |
| `.claude/skills/deps_audit/SKILL.md` | `/deps_audit` — CVE scan + license compliance gate | — |
| `.claude/skills/security_scan/SKILL.md` | `/security_scan` — grep src/ for RULES.md §5 forbidden patterns (review step 6 gate) | — |
| `.claude/settings.json` | Permissions (deny git/gh/curl/wget) + wires the four hooks | — |
| `.claude/hooks/PreToolCall` | Workspace-boundary enforcement (blocks reads/writes outside repo + git/gh/curl/wget) | — |
| `.claude/hooks/PostToolCall` | Warn when tool output contains apparent secrets | — |
| `.claude/hooks/Stop` | Reminder to run tests before session close | — |
| `.claude/hooks/Notification` | Append events to `.claude/logs/events.log` | — |
| `.claude/agents/spec_writer.md` | Write `docs/spec/<module>.md` for a module | — |
| `.claude/agents/test_writer.md` | Generate failing test from a spec | — |
| `.claude/agents/code_reviewer.md` | Procedure B steps 6-7 analysis (findings only) | — |
| `.claude/templates/module_spec.md` | `docs/spec/` skeleton | — |
| `decisions/DECISIONS.md` | Architectural decision log — format + DEC-001 example | — |

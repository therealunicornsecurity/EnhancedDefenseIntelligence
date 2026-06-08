# Claude Code Workspace — DEVKIT (meta-repo)

> `templates/RULES.md` is law (it becomes the downstream `RULES.md`). Read it before any work.
> Local-only rule additions go in `.claude/CLAUDE.local.md` (not synced, not committed).

This is the kit's own meta-repo. Downstream repos scaffolded via `edi.sh init` receive their own `.claude/CLAUDE.md` from `templates/CLAUDE.md`.

## File Ownership Tiers (templates/RULES.md §10)

| Tier | Label    | `edi.sh update` behavior                  |
|------|----------|-------------------------------------------|
| 1    | Law      | Force-sync from kit — local edits lost    |
| 2    | Scaffold | Written at init only — never overwritten  |
| 3    | Merge    | Added if missing — kept if present        |
| 4    | Local    | Never touched                             |

Rules cannot be overwritten by local edits. Edit `templates/RULES.md` directly,
or add overrides to `.claude/CLAUDE.local.md` (Tier 4).

## Claude-Specific Rules
1. NEVER run commands outside this repo without explicit permission
2. NEVER run ANY git or remote command without explicit permission
3. NEVER guess from cached knowledge — state limitation and ask

## Commands
| Slash command | Triggers                                |
|---------------|-----------------------------------------|
| /procedure_a  | TDD procedure (RULES.md §3)             |
| /procedure_b  | Code review (RULES.md §4)               |
| /new_tool     | Scaffold new repo via edi.sh            |
| /freeze       | Snapshot with next codename             |
| /tag          | Patch/minor/major version bumper        |

## Skills
| Slash command   | Purpose                                  |
|-----------------|------------------------------------------|
| /commit_format  | Commit type reference (RULES.md §7)      |
| /review         | Structured code review                   |
| /refactor       | Systematic refactoring                   |
| /test_gen       | Generate test suites                     |
| /perf_benchmark | Before/after benchmark (review step 8)   |
| /deps_audit     | CVE scan + license compliance gate       |
| /security_scan  | Grep RULES.md §5 forbidden patterns (review step 6) |

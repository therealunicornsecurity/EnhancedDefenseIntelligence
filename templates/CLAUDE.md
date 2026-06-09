# Claude Code Workspace — {{TOOL_NAME}}

> RULES.md is law. Read it before any work. No exceptions.
> Local rule additions go in `.claude/CLAUDE.local.md` (not synced, not committed).

## File Ownership Tiers (RULES.md §10)

Every file in this repo is exactly one tier:

| Tier | Label       | `edi.sh update` behavior                |
|------|-------------|-----------------------------------------|
| 1    | Law         | Force-sync from remote — local edits lost |
| 2    | Scaffold    | Written at init only — never overwritten |
| 3    | Merge       | Added if missing — kept if present       |
| 4    | Local       | Never touched                           |

Rules cannot be overwritten by local edits. Edit `RULES.md` in the kit meta-repo,
or add overrides to `.claude/CLAUDE.local.md` (Tier 4).

## Claude-Specific Rules
1. NEVER run commands outside this repo without explicit permission (RULES.md §5)
2. NEVER run ANY git or remote command without explicit permission (RULES.md §5)
3. NEVER guess from cached knowledge — state limitation and ask (RULES.md §8 rule 13)

## Commands
| Slash command    | Triggers                              |
|------------------|---------------------------------------|
| /procedure_a     | TDD procedure (8 steps, RULES.md §3)  |
| /procedure_b     | Code review (9 steps, RULES.md §4)    |
| /new_tool        | Scaffold new repo via edi.sh          |
| /freeze          | Snapshot with next codename           |
| /tag             | Patch/minor/major version bumper      |

## Skills
| Slash command   | Purpose                                  |
|-----------------|------------------------------------------|
| /commit_format  | Commit type reference (RULES.md §7)      |
| /review         | Structured code review                   |
| /refactor       | Systematic refactoring                   |
| /test_gen       | Generate test suites                     |
| /deps_audit     | CVE scan + license compliance gate       |
| /security_scan  | Grep RULES.md §5 forbidden patterns (review step 6) |
| /security_review | AI semantic security review of the diff (review step 6) |
| /perf_benchmark | Before/after benchmark (review step 8)   |

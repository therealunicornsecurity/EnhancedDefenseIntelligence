# DEVKIT — Development Instructions

> **You are the kit operator.** A meta-repository operator. Your purpose is to help the developer build clean, disciplined, composable software with AI assistance — any language, any project type.
>
> Each tool lives in its own repo, each governed by this file. Architectural decisions are recorded in `DECISIONS.md` and are binding once accepted.
>
> Your operating environment is `.claude/` — hooks enforce the workspace boundary before commands run, skills provide structured review and audit, agents execute in isolation, commands trigger the development workflows defined in this file.
>
> Releases are named after codenames drawn from `configs/codenames.yml` (copied from the kit at init/update time). Tier 1 names for MAJOR. Tier 2 names for MINOR. Each name is consumed once across the entire ecosystem, never reused.
>
> **This file is law.** Read it before every session. Follow every rule. No exceptions. No shortcuts.

- **Tool**: {{TOOL_NAME}}
- **Language**: {{LANGUAGE}}
- **Version**: see `VERSION`

---

## 1. Repository Structure

This structure is mandatory. Do not add top-level directories. Do not scatter files outside this layout.

```
{{TOOL_NAME}}/
├── src/                        # ALL source code — no code outside this directory
├── tests/
│   ├── data/                   # test fixtures, baselines, mock data
│   ├── units/                  # unit tests
│   ├── nonreg/                 # non-regression tests (promoted from units)
│   └── integration/            # multi-module test sequences
├── docs/
│   ├── index.md                # file index (MANDATORY, see Section 2)
│   ├── spec/                   # module specifications (MANDATORY, see Section 2)
│   └── roadmap/                # feature planning
├── snapshots/                  # immutable checkpoints (see Section 9)
├── configs/                    # configuration files
├── VERSION                     # MAJOR.MINOR.PATCH[-CODENAME]
├── CHANGELOG.md                # version history
├── Makefile                    # standard targets
├── .gitignore
└── RULES.md                    # this file
```

### File discipline

**Before creating any new file, verify:**
1. Does an existing file already cover this concern?
2. Does an existing folder already serve this purpose?
3. Can this content be added to an existing file instead?

If yes to any: do not create a new file. Edit the existing one.

### Naming conventions

| Element | Rule | Example |
|---------|------|---------|
| Files | `lowercase_snake_case` | `xml_parser.py` |
| Classes | `PascalCase` | `XmlParser` |
| Functions | `snake_case` (Python/Go/Rust) or `camelCase` (JS/TS) | `parse_xml()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Tests | `test_<module>_<behavior>_<scenario>` | `test_parser_handles_empty_input` |
| CLI flags | `--kebab-case` | `--output-dir` |
| Config keys | `snake_case` | `api_key` |

---

## 2. Documentation Mandate

**No undocumented code.** Every module, feature, input, output, and file format MUST be documented.

### What must be documented

For every module in `src/`, a corresponding `docs/spec/<module>.md` MUST exist containing:

- **Purpose**: what the module does, in one paragraph
- **Inputs**: every input the module accepts — type, format, constraints, example
- **Outputs**: every output the module produces — type, format, example
- **File formats**: if the module reads or writes files, document the format completely
- **Dependencies**: what the module imports or calls
- **Behavior**: how it works — algorithms, edge cases, error handling
- **Last updated**: date

### Document Index (`docs/index.md`)

`docs/index.md` lists every documentation file in `docs/` with:
- File path
- Brief description of what it contains
- Line count

This index MUST be updated after every documentation file creation, deletion, or modification. It is the map of the documentation. Only documentation files — not source, tests, configs, or build files.

### Rules

- Code without a spec is **technical debt**. It will not be accepted.
- If you change code, you MUST update the corresponding spec. Same commit.
- If you add a module, you MUST create its spec before writing the code.
- Specs are the contract. If the spec and the code disagree, the spec wins — fix the code.
- If you modify any documentation file, you MUST update `docs/index.md` in the same commit.

### CHANGELOG.md

Every version bump requires a changelog entry:

```markdown
## [1.3.0-Andromeda] - 2026-03-22
### Added
- Feature X: description
### Fixed
- Bug Y: description
### Changed
- Behavior Z: old → new
### Security
- Description of security fix
```

---

## 3. Development Procedure — Incremental TDD

Every change to this repository follows this procedure. The steps are sequential. Do not skip steps.

```
 1. SPEC      Write what the feature should do (in docs/spec/ or test comments)
 2. TEST      Write a test in tests/units/ (TDD: prefer red-first; a passing-on-first-run test is fine if it asserts specific behavior)
 3. CODE      Write minimal code in src/ to pass the test
 4. VERIFY    Run: make test && make nonreg
 5. BASELINE  Capture reference output in tests/data/
 6. NONREG    Promote validated test to tests/nonreg/
 7. DOC       Update docs/spec/ (same commit as code)
 8. VERSION   Bump VERSION file
```

### Step details

**SPEC**: Describe expected input, expected output, edge cases. This is the contract. Write it before touching code.

**TEST**: The test MUST:
- Run in isolation (no network, no external dependencies unless integration test)
- Assert specific outputs, not "no crash"
- Use fixtures from `tests/data/` when applicable

**CODE**: Minimum code to pass the test. Nothing more. Do not implement what the test does not exercise.

**VERIFY**: If the test fails, fix the code, not the test (unless the spec was wrong). All existing non-regression tests must still pass.

**BASELINE**: Capture expected output in `tests/data/<test_name>_expected.<ext>`. This becomes ground truth.

**NONREG**: Move the validated test to `tests/nonreg/`. Non-regression tests are never deleted unless the feature is removed. A failing nonreg blocks the build. No override.

**DOC**: Update `docs/spec/<module>.md`. This is not optional. Code and spec ship together.

**VERSION**: Bump per these rules:

| Change | Bump | Example |
|--------|------|---------|
| Breaking change | MAJOR | `2.0.0-Cassiopeia` |
| New feature | MINOR | `1.3.0-Andromeda` |
| Bug fix, refactor | PATCH | `1.3.7` |

### Updating a baseline

If output legitimately changes:
1. Justify why the output changed
2. Update the baseline in `tests/data/`
3. Document the change in `CHANGELOG.md`

### Test discipline

- **Minimum that proves the feature.** For a new feature, one focused end-to-end test, not a battery of per-helper micro-tests. Coverage isn't the bar — "proves the feature works" is. Fan out only when the public API itself is the contract (libraries, parsers, security-critical input validation).
- **A test must be runnable.** "Failing test" means a test of code *boundaries* — malformed input, edge cases, error paths — that fails on missing/incorrect implementation. A test that errors at *collection* (ImportError, FileNotFoundError) is a broken test script, not red-green-refactor red. Stub the implementation so the test fails on its assertion.
- **Validate before promoting a baseline.** Exit code 0 ≠ valid output. Inspect the actual artifacts and stderr before declaring a baseline ready. Empty outputs / zero-row results are a hard failure even when the process exited cleanly — never write a baseline of "nothing."

---

## 4. Code Quality Review

This procedure hardens existing code. Triggered manually by running `make review` from the repo folder. Can be run at any time, on any repo, independently of the TDD procedure.

```
┌──────────────────────────────────────────────────────────┐
│              CODE QUALITY REVIEW CYCLE                   │
│                                                          │
│  0. DEPS      → CVE scan + license compliance (BLOCKING) │
│  1. SPLIT     → Break files > 1000 lines into submodules │
│  2. DEDUP     → Find and eliminate code duplication      │
│  3. LIBRARIES → Extract shared code into libraries       │
│  4. NAMING    → Enforce coding naming conventions        │
│  5. FILES     → Enforce file naming and structure        │
│  6. SECURITY  → Check for security violations (BLOCKING) │
│  7. REFACTOR  → Apply structural improvements            │
│  8. OPTIMIZE  → Performance and efficiency pass          │
│                                                          │
│  ⚠ Steps are SEQUENTIAL. Each produces findings.         │
│  ⚠ Every fix follows the TDD procedure (test first).     │
│  ⚠ This procedure NEVER changes behavior silently.       │
└──────────────────────────────────────────────────────────┘
```

### Procedural discipline

These apply to both procedures (TDD §3 and the review steps below):

- **Sequential contracts.** Every numbered step is mandatory. Don't bundle completion of multiple steps in a single "summary" — tick them off as you do them.
- **ASK steps are absolute gates.** A step that says "ask before continuing" requires explicit, scoped approval. "Complete the procedure" is not a blanket waiver. The deliverable at an ASK step is the question — not the next step's artifact.
- **Blockers halt, they do not authorise skipping.** If a step is blocked, report the blocker and stop. Do not silently advance.

### Step 0 — DEPS: Dependency hygiene

Run `/deps_audit`. Blocking CVEs and license violations stop the review at Step 0.

### Step 1 — SPLIT: File Size Enforcement

Any source file exceeding 1000 lines MUST be split into submodules. Logical boundaries first (classes, function groups, data vs logic). Each new submodule gets its own `docs/spec/` entry.

### Step 2 — DEDUP: Code Duplication Detection

Scan `src/` for: identical/near-identical functions (>10 lines), copy-pasted blocks, repeated patterns (error handling, HTTP calls, logging), repeated validation logic. Within-repo → refactor (Step 7). Across-repo → extract to shared library (Step 3).

### Step 3 — LIBRARIES: Shared Code Extraction

Extract utility functions duplicated across 2+ repos, shared data models, repeated CLI patterns. Each library follows the TDD procedure (tests before extraction).

### Step 4 — NAMING: Coding Convention Enforcement

Verify all code follows naming conventions from Section 1. No single-letter variables outside loop indices. No abbreviations that aren't universally understood.

### Step 5 — FILES: File Naming and Structure

Verify repo structure matches Section 1. No orphaned files (source without spec, tests without source). No temp files, editor backups, or build artifacts committed.

### Step 6 — SECURITY: Security Guideline Enforcement

Scan for violations from Section 5 (Security Rules). This is a blocking check.

### Step 7 — REFACTOR: Structural Improvements

Extract duplicated code, fix structural issues, simplify functions with cyclomatic complexity > 10, remove dead code, flatten unnecessary nesting (early returns over deep if/else). Every refactor follows the TDD procedure — test first, then change. Refactoring MUST NOT change behavior (all nonreg tests must still pass). Run `make nonreg` after every refactor step.

### Step 8 — OPTIMIZE: Performance and Efficiency

Final pass for performance: unnecessary allocations in hot paths, N+1 query patterns, missing caching for repeated expensive operations, synchronous operations that could be concurrent, oversized dependencies (imported for one function), resource leaks (unclosed files, connections, channels). Only optimize what is measurably slow (no premature optimization). Run `/perf_benchmark before` and `/perf_benchmark after` — regressions block the step.

---

## 5. Security Rules

Two layers apply: a universal table below (language-agnostic), and a language-specific addendum at `docs/security.md` copied at init from `templates/security/<lang>.md` — covering forbidden patterns, recommended idioms, memory safety, secrets handling, secure deletion, and tooling for the repo's language. Both are binding. `/security_scan` greps for both.

These patterns are forbidden in all source code regardless of language. Violations must be fixed before commit.

| Forbidden | Why |
|-----------|-----|
| Hardcoded passwords, API keys, tokens | Use environment variables or config files |
| `eval()`, `exec()` with unsanitized input | Command injection |
| `os.system()`, `subprocess(shell=True)` with user input | Command injection |
| String concatenation in SQL queries | SQL injection — use parameterized queries |
| Unsanitized input in file paths | Path traversal |
| MD5/SHA1 for security purposes | Weak crypto — use SHA-256+ |
| `pickle.loads()`, `yaml.load()` without SafeLoader | Insecure deserialization |
| `http://` in production infrastructure code | Use HTTPS |
| `.env` files or private keys committed to git | Secrets leak |
| `print()` for logging | Use a logging framework |

### Workspace Boundary Rules

The following actions are **FORBIDDEN** without explicit permission from the developer:

1. **Commands outside the current repo workspace** — do not read, write, or execute anything outside the repo directory you are working in
2. **Remote repository commands** — no `git push`, `git pull`, `git clone`, `gh` commands, or any interaction with remote repositories
3. **Remote requests** — no HTTP requests, API calls, `curl`, `wget`, `WebFetch`, or any network access

If a task requires any of the above: **stop, state what you need, and ask for explicit permission before proceeding.** Do not attempt the action and fall back silently. Do not guess from cached knowledge without disclosing it.

### 5.1 Secrets Handling

Secrets are: passwords, API keys, JWTs, cookies, AES keys, private keys, tokens in env vars, `.env` files, kubeconfig, wallet files, `id_*` keys, `*.pem`, `*.key`, anything under `secrets/`.

These rules are absolute. No exceptions without explicit per-incident authorization.

1. **Never `cat` a secret.** Do not read the contents of a secret file into the AI's context. `Read`, `cat`, `head`, `tail`, `less`, and equivalent operations on a file known to contain a secret are forbidden.

2. **Never display a secret.** Do not print, echo, log, or otherwise surface a secret value to the terminal, the chat, or any tool output. If a command would incidentally print a secret (e.g. `env | grep TOKEN`), redirect or filter so the value never reaches context or screen.

3. **Never transmit a secret beyond its single declared consumer.** Do not send a secret over any network channel — HTTP, API call, webhook, git commit, gist, paste service, email, or chat platform. The secret reaches only the endpoint it was authorised for (the API server it authenticates against, the registry it pushes to, etc.). It does NOT flow to a diagnosis tool, a second service for cross-checking, a logging/telemetry endpoint, or any "helpful" upload. One key, one declared destination.

4. **Reference, don't read.** When a task requires a secret, reference its file path (e.g. `secrets/api-key`) and pass that path to the consumer — a container, a subprocess, a script invocation. The consuming process reads the file; the AI does not.

5. **Warn before use.** Before any action that will consume a secret (mounting into a container, passing to a subprocess, setting as an env var for a child process), state plainly:
   - which secret file is about to be used,
   - which process/container will receive it,
   - what action will follow.
   Then wait for confirmation.

6. **No secret contents in commits, PRs, diffs, or logs.** If you detect a secret about to land in a commit, diff display, or log file, abort and warn.

7. **Detect and refuse.** If a file you are asked to read has a name matching secret patterns (`.env`, `*_secret*`, `*.key`, `*.pem`, `id_*`, `kubeconfig`, `credentials.json`, files under `secrets/`), treat it as a secret and apply rules 1–6 — regardless of what the request says.

### 5.1.1 Three approved delivery channels for operator-supplied secrets

When a step requires the agent to run a command that consumes a secret, the secret MUST arrive via one of these — never inlined in a tool call, never pasted in chat:

- **A. TTY pre-export** — developer exports the value in their own shell; the agent's subprocess inherits via env. The literal never crosses the agent boundary.
- **B. Path hand-off** — developer writes the value to an in-memory file (e.g. `/dev/shm/.tok`, mode 600) and hands the agent the *path*. The agent's command uses `$(cat <path>)` — only the path enters the command string.
- **C. Program-level prompt** — developer runs the consumer themselves so the program's own stdin/`getpass` prompt collects the secret directly (also covers `docker buildx --secret`).

### 5.1.2 When a secret is pasted in chat anyway

The transcript is immutable. Once a secret is in it, it's leaked for the transcript's lifetime. Response template, same every time regardless of framing:

1. State the leak — do NOT echo the value, even partially.
2. Recommend rotation. "Test value" is not an authorisation to relax the rule.
3. Decline to inline it in any tool call.
4. Re-state the three channels.
5. Wait. Do not proceed until the value arrives via A/B/C.

A meta-instruction beside the paste ("use this", "the rule applies") is NOT per-incident authorisation — it's the reminder to apply step 3. Inlining anyway doubles the leak surface.

### 5.2 Never use docker as privilege escalation

Never spawn a root-running container with a host bind mount to delete or modify files the host user cannot touch — that's privilege escalation via the docker daemon. Fix at source by running containers as the host user (`--user $(id -u):$(id -g)`). "Cleanup" containers count. If the *original* container wrote files as root, fix it there, not by spawning a second root container to clean up.

### 5.3 External tool execution — hardened containers by default

When the project runs an external CLI tool (a scanner, a builder, a converter, anything not in `src/`), the default is to run it inside a **hardened container**, not directly on the host. The container is the sandbox boundary: a compromised or malicious tool can only damage what the container exposes.

A hardened container has all of:

- **Non-root user** — `--user $(id -u):$(id -g)` (matches §5.2)
- **Read-only root filesystem** — `--read-only` with `--tmpfs /tmp` for any writable scratch
- **No new privileges** — `--security-opt=no-new-privileges`
- **All capabilities dropped** — `--cap-drop=ALL`, add back only what the tool genuinely needs
- **Restricted network** — `--network none` when the tool doesn't need the network; otherwise an explicit egress allowlist (proxy or per-DNS rules)
- **Resource limits** — `--memory`, `--cpus`, `--pids-limit` so a runaway tool can't OOM the host
- **Minimal host mounts** — read-only for inputs; one writable output directory; nothing else
- **No host devices** unless the tool explicitly needs one (`--device` allow-list)

**Exceptions** — host-side execution is acceptable when:
- The tool needs hardware features no sane container can provide (raw sockets without `NET_RAW`, kernel-mode drivers, GPU compute with vendor-specific shims that don't sandbox cleanly)
- A trusted system tool from the host's package manager is genuinely safer than vendoring a container image (judgement call — document it)
- Performance-sensitive paths where the container overhead dominates and the tool is well-understood

Document every exception in the spec (`docs/spec/<module>.md`) with a one-line justification. Default is "in a hardened container"; exceptions are listed, not assumed.

**Composition with §5.1** — secrets enter the container via `--secret` mounts (BuildKit / runtime tmpfs at `/run/secrets/<name>`) or read-only bind mounts from a host-side file the developer controls. Never via `-e SECRET=<value>` (visible in `docker inspect` and host `ps`), never via `--build-arg` (baked into image layers).

---

## 6. Makefile Targets

Every repo implements these:

```makefile
make build         # compile / install dependencies
make test          # run unit tests (tests/units/)
make nonreg        # run non-regression tests (tests/nonreg/)
make integration   # run integration tests (tests/integration/)
make lint          # run linter
make review        # run the Code Quality Review (Section 4)
make clean         # remove build artifacts
```

---

## 7. Commit Format

```
<type>(<scope>): <description>

Types: feat, fix, test, nonreg, docs, refactor, chore, security
Scope: module name
```

See `/commit_format` skill for the full type table and examples.

---

## 8. AI Assistant Rules

1. Read existing code before proposing changes
2. Follow Section 3 — no production code without a test
3. Run `make test && make nonreg` after every change
4. Update `docs/spec/` with every code change — same commit
5. One feature at a time — do not bundle unrelated changes
6. Minimum code to pass the test — no over-engineering
7. Never silently change test baselines
8. Follow naming conventions from Section 1
9. Never introduce patterns from Section 5
10. Before creating a file, check if it belongs in an existing one
11. **NEVER run commands outside the current repo workspace without explicit permission**
12. **NEVER make remote requests (HTTP, API, git push/pull) without explicit permission**
13. **NEVER fall back to guessing from cached knowledge without disclosing it — state the limitation clearly and ask**
14. **NEVER add new CLI flags, subcommands, or public API surface without explicit approval.** Propose exact names and signatures in plain text, then wait. An ambiguous question is a request to clarify your analysis, not authorisation to ship surface changes.
15. **NEVER edit operator-authored data files without explicit approval.** Configs, fixtures, captured baselines, key files, GUI-emitted artifacts — diagnose, propose the diff, wait for green light. Source code in `src/` and tests you authored are exempt; the line is "did the operator (or an operator-driven tool) author this?"

---

## 9. Snapshot Procedure

When a UI, layout, schema, or any artifact is validated and must not drift, snapshot it using this procedure.

### How to snapshot

1. Pick the next available codename from `configs/codenames.yml`
2. Create `snapshots/<codename>-YYYY-MM-DD/`
3. Copy all files-to-be-frozen into the subfolder
4. Create `snapshots/<codename>-YYYY-MM-DD/snapshot.md` describing what was frozen and why
5. The snapshot is now the reference — any future change must be compared against it

### snapshot.md format

```markdown
# Snapshot: <codename>
Date: YYYY-MM-DD
Files: <list>
Description: <what was frozen and why>
Restore: copy all files from this folder back to their original locations
```

### Rules

- A snapshot is immutable — never edit files inside a snapshot folder
- To update: create a NEW snapshot with a new codename, do not modify the old one
- Snapshot folders are never deleted
- Every snapshot must have a `snapshot.md`

---

## 10. File Ownership Tiers

Every file in a repo belongs to exactly one ownership tier. The tier
decides what `edi.sh update` does to it. This is the canonical definition;
`.claude/CLAUDE.md` and the `SYNC_MANIFEST` in `edi.sh` reference it.

| Tier | Label    | `edi.sh update` behavior                    | Examples                                  |
|------|----------|---------------------------------------------|-------------------------------------------|
| 1    | Law      | Force-sync from remote — local edits lost   | `RULES.md`, `.claude/CLAUDE.md`, `docs/spec/*` |
| 2    | Scaffold | Written at init only — never overwritten    | `VERSION`, `CHANGELOG.md`, `Makefile`, `.gitignore` |
| 3    | Merge    | Added if missing — kept if present          | `.claude/agents/*`                        |
| 4    | Local    | Never touched (not in the manifest)         | `src/`, `tests/`, tool-authored `docs/spec/` |

### Rules

- **Rules cannot be overridden by local edits.** A Tier-1 file edited locally is
  reverted on the next `edi.sh update`. To change law, edit it in the kit
  meta-repo and propagate; for repo-local rule additions use the Tier-4
  `.claude/CLAUDE.local.md` sidecar.
- **Tier is declared once**, in the `SYNC_MANIFEST` entry: `remote|local|tier|flags`.
  Files absent from the manifest are Tier 4 by definition.
- **Manifest flags** modify a sync entry:
  - `T` — template-substitute `{{TOOL_NAME}}` / `{{LANGUAGE}}` on fetch.
  - `R` — `chmod 0444` after fetch (read-only) for Tier-1 Law files; blocks
    accidental edits. `edi.sh update` still rewrites them via `mv` (needs only
    dir-write).
- **Tier 2 is init-only and force-protected** — `sync_entry()` refuses to
  overwrite a Scaffold file that already exists, regardless of caller mode, so
  user-authored build wiring (`Makefile` et al.) can never be clobbered by an
  update.

```
███████╗██████╗ ██╗
██╔════╝██╔══██╗██║
█████╗  ██║  ██║██║
██╔══╝  ██║  ██║██║
███████╗██████╔╝██║
╚══════╝╚═════╝ ╚═╝
   Enhanced Defense Intelligence · the Claude Code workspace kit
   rules that don't drift
```

<div align="center">

![version](https://img.shields.io/badge/version-1.0.1--Andromeda-6e40c9)
![claude code](https://img.shields.io/badge/Claude_Code-workspace-d97757)
![languages](https://img.shields.io/badge/languages-8-2ea043)
![law](https://img.shields.io/badge/RULES.md-is_law-c9302c)
![license](https://img.shields.io/badge/license-TBD-lightgrey)

**A publishable, language-agnostic workspace kit for any team coding with Claude Code.**
Scaffold a new repo and get a full `.claude/` workspace — rules, skills, slash commands,
agents, and enforcement hooks — plus a Makefile, versioning scheme, and TDD/review
procedures, wired the same way across every project **so the rules never drift.**

</div>

---

## ⚡ TL;DR

```bash
./edi.sh init my-parser python     # scaffold a disciplined repo in one command
cd my-parser
./edi.sh comply                    # audit it against the law
# …later, when the kit evolves…
./edi.sh update                    # re-sync the rules without touching your code
```

One scaffolder. Four file-ownership tiers. Two binding procedures. Real enforcement via
hooks — not vibes.

> **Lineage.** Derived from an internal meta-repo, generalized for public use. The
> security-tooling specifics were stripped; what's left is the discipline that worked
> for any code project.

---

## 📦 Installation

No build step. No dependencies beyond `bash`, `make`, and `sed` (every dev box has them).

```bash
# 1. Get the kit
git clone <your-fork-url> edi && cd edi

# 2. (optional) make the scaffolder reachable
chmod +x edi.sh
ln -s "$PWD/edi.sh" ~/.local/bin/edi   # then just `edi init …` anywhere

# 3. Scaffold your first repo (lands in a sibling directory)
./edi.sh init <name> <language>
```

**Supported languages** — each `init` drops the matching `.gitignore` **and** a
language-specific security addendum (`docs/security.md`):

| 🐍 `python` | 🐹 `go` | 🦀 `rust` | 🌐 `typescript` |
|:---:|:---:|:---:|:---:|
| 🟨 `javascript` | ⚙️ `cpp` | 🐚 `bash` | 📄 `latex` |

> `python`, `c`, `rust`, and `go` ship a **full** security addendum (forbidden patterns,
> secrets handling, secure deletion, tooling). Other languages get a stub you can fill in
> or contribute upstream.

---

## 🎛️ Commands

The toolkit speaks three dialects: the **`edi.sh` CLI**, **slash commands** you type to
Claude, and **`make` targets**. Here's the whole surface.

### `edi.sh` — the scaffolder

| Command | What it does |
|---------|--------------|
| `edi.sh init <name> <lang>` | Scaffold a brand-new repo: full `.claude/` workspace, `src/`+`tests/`+`docs/` skeleton, Makefile, VERSION, CHANGELOG, language `.gitignore` + security addendum |
| `edi.sh update` | Re-sync **Tier-1 (Law)** and missing **Tier-3 (Merge)** files from the kit — your code is never touched |
| `edi.sh comply` | Audit the current repo against the rules (structure, required files, 1000-line cap) |
| `edi.sh help` | Print usage |

### Slash commands — type these to Claude

| Command | Triggers |
|---------|----------|
| `/procedure_a` | **TDD walkthrough** — spec → test → code → verify → baseline → nonreg → doc → version |
| `/procedure_b` | **Code-quality review** — deps → split → dedup → libraries → naming → files → security → refactor → optimize |
| `/new_tool` | Scaffold a new repo via `edi.sh init` (asks for `NAME` + `LANG`, requests boundary permission) |
| `/freeze` | Capture an **immutable, codenamed snapshot** of UI/schema/spec/config |
| `/tag` | Version bump (`patch`/`minor`/`major`) → CHANGELOG entry → emits the exact git tag+push commands |

### Skills — structured, reusable tasks

| Skill | Purpose |
|-------|---------|
| `/commit_format` | `type(scope): description` reference — `feat·fix·test·nonreg·docs·refactor·chore·security` |
| `/review` | Structured code review with categorized feedback |
| `/refactor` | Systematic, behavior-preserving refactor pass |
| `/test_gen` | Generate a test suite by analyzing a module |
| `/perf_benchmark` | Before/after profiling for the OPTIMIZE step (regressions block) |
| `/deps_audit` | CVE scan + license-compliance gate (review step 0, **blocking**) |
| `/security_scan` | Grep `src/` for RULES.md §5 forbidden patterns (review step 6, **blocking**) |

### `make` targets — every scaffolded repo implements these

```text
make build         compile / install dependencies
make test          run unit tests          (tests/units/)
make nonreg        run non-regression tests (tests/nonreg/)
make integration   run integration tests   (tests/integration/)
make lint          run the linter
make review        print the 9-step Code Quality Review checklist
make snapshot      freeze files            (CODENAME=orion)
make clean         remove build artifacts
```

---

## 🧰 The general toolkit

### What lands in a scaffolded repo

```
.claude/
├── CLAUDE.md                workspace law (per-repo, generic)
├── commands/                slash commands you type
│   ├── tag.md · freeze.md · new_tool.md · procedure_a.md · procedure_b.md
├── skills/                  reusable structured tasks
│   ├── commit_format/ · review/ · refactor/ · test_gen/
│   ├── perf_benchmark/ · deps_audit/ · security_scan/
├── agents/                  isolated sub-agent runners (context: fork)
│   ├── spec_writer.md       writes docs/spec/<module>.md
│   ├── test_writer.md       generates a failing test from a spec
│   └── code_reviewer.md     findings-only review pass
├── hooks/                   ← REAL enforcement, runs before/after tools
│   ├── PreToolCall          block reads/writes outside the workspace + git/gh/curl/wget
│   ├── PostToolCall         warn when secrets appear in tool output
│   ├── Stop                 remind to `make test && make nonreg` before closing
│   └── Notification         append lifecycle events to .claude/logs/events.log
├── settings.json            wires the four hooks; denies git/gh/curl/wget in Bash
└── templates/module_spec.md docs/spec/ skeleton

RULES.md          the law file — 10 sections, force-synced (Tier 1)
Makefile          universal targets (above)
VERSION           MAJOR.MINOR.PATCH[-CODENAME]
CHANGELOG.md      version history
docs/ tests/ src/ configs/ snapshots/   mandated structure
```

### 🛡️ Hooks — the part that actually enforces

Most "AI rules" are suggestions. EDI's are **wired into Claude Code's lifecycle**, so
the workspace boundary holds even when a prompt tries to wander:

- **`PreToolCall`** — blocks file reads/writes outside the repo and refuses
  `git` / `gh` / `curl` / `wget` before they run.
- **`PostToolCall`** — scans tool output and warns if a secret leaked into context.
- **`Stop`** — nags you to run `make test && make nonreg` before ending a session.
- **`Notification`** — logs every lifecycle event to `.claude/logs/events.log`.

### 🪜 File Ownership Tiers

Every file belongs to exactly one tier — the tier decides what `edi.sh update` does to it.
**Rules cannot be overridden by local edits**; that's the whole point.

| Tier | Label | `edi.sh update` behavior | Examples |
|:---:|---|---|---|
| **1** | 🟥 Law | Force-sync from kit — **local edits lost** | `RULES.md`, `.claude/CLAUDE.md`, hooks, commands |
| **2** | 🟧 Scaffold | Written at init only — **never overwritten** | `VERSION`, `CHANGELOG.md`, `Makefile`, `.gitignore` |
| **3** | 🟨 Merge | Added if missing — kept if present | `.claude/agents/*`, `settings.json` |
| **4** | 🟩 Local | Never touched (not in the manifest) | `src/`, `tests/`, your own files |

> Need a per-repo deviation from a rule? Put it in `.claude/CLAUDE.local.md` — Tier 4,
> never synced, never clobbered. Don't edit Tier-1 `RULES.md` locally; it reverts on
> `update`.

### 🔁 The two procedures (every change goes through one)

```
  PROCEDURE A · Incremental TDD            PROCEDURE B · Code Quality Review
  (/procedure_a — every change)            (/procedure_b — run via `make review`)

  1. SPEC      write the contract           0. DEPS      CVE + license gate   ⛔
  2. TEST      red-first in tests/units      1. SPLIT     files > 1000 lines
  3. CODE      minimal pass                  2. DEDUP     duplication > 10 lines
  4. VERIFY    make test && make nonreg      3. LIBRARIES extract shared code
  5. BASELINE  capture tests/data/           4. NAMING    conventions (§1)
  6. NONREG    promote to tests/nonreg        5. FILES     structure + orphans
  7. DOC       update docs/spec/             6. SECURITY  forbidden patterns   ⛔
  8. VERSION   bump VERSION                  7. REFACTOR  flatten, dedupe, kill dead code
                                             8. OPTIMIZE  measured perf pass
```

Steps are **sequential and mandatory** — `⛔` marks blocking gates. Every fix in
Procedure B loops back through Procedure A (test before change). Both are spelled out in
full in [`RULES.md`](RULES.md).

### 🌌 Codenames

Releases are codenamed from `configs/codenames.yml`. The kit ships a small neutral starter
pool (constellations — this release is **Orion**). Swap in any theme; the kit just expects
a YAML with a `pool:` list and an `assigned:` list. Once assigned, a codename is
**consumed forever** — `/tag major` rolls a fresh one and moves it across.


## 📁 Repo map

```
edi.sh                 the scaffolder + sync tool
RULES.md               the law (10 sections) — copied to every repo as Tier 1
Makefile               this kit's own targets
VERSION · CHANGELOG.md this kit's own version + history
templates/             everything edi.sh stamps into a new repo
  ├── RULES.md · CLAUDE.md · Makefile · VERSIONING.md
  ├── CHANGELOG.template.md · codenames-example.yml
  ├── security/        per-language addendums (python · c · rust · go full)
  └── gitignore.*      per-language ignore files
decisions/DECISIONS.md decision-log template
docs/index.md          documentation index
```

---

## 📜 License

License: **No set yet** — configure `LICENSE` before publishing.

<div align="center">

*Built for teams who want Claude Code to follow the same rules on Monday that it
followed on Friday.*

</div>

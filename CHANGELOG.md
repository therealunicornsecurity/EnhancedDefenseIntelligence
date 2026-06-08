# Changelog

All notable changes to DEVKIT are recorded here. Format follows the kit's own VERSIONING.md.

## [1.0.0-Andromeda] - 2026-06-08
### Changed
- **BREAKING:** renamed the scaffolder `kit.sh` → `edi.sh`; all references updated across the repo (`SYNC_MANIFEST`, commands, skills, docs, RULES).
- Hardened `/tag`: the step-7 output is the git command block only — no co-author / AI / sign-off trailers — with a worked example embedded in the command.
- Rewrote and rebranded the README: DEVKIT → EDI (Enhanced Defense Intelligence).
### Added
- `configs/codenames.yml` bootstrapped from `templates/codenames-example.yml`; `Orion` (0.1.0) marked consumed and `Andromeda` assigned to 1.0.0.

## [0.1.0-Orion] - 2026-05-25
### Added
- Initial publishable cut. Workspace kit for general coding teams using Claude Code: `templates/RULES.md` (the law file, 10 sections), `edi.sh` scaffolder, per-language `.gitignore` templates, universal `Makefile`, `VERSIONING.md` (`MAJOR.MINOR.PATCH[-CODENAME]` scheme), `codenames-example.yml` (constellations starter pool), `decisions/DECISIONS.md` (decision log template).
- `.claude/` workspace: `CLAUDE.md`, five slash commands (`tag`, `freeze`, `new_tool`, `procedure_a`, `procedure_b`), six skills (`commit_format`, `review`, `refactor`, `test_gen`, `perf_benchmark`, `deps_audit`), three agents (`spec_writer`, `test_writer`, `code_reviewer`), `module_spec.md` template, `.claude/docs/index.md`.
- Four-tier file ownership system (Law / Scaffold / Merge / Local) so `edi.sh update` can re-sync rule changes without clobbering user code.
- Two binding procedures: TDD (`/procedure_a`, 8 steps) and Code Quality Review (`/procedure_b`, 9 steps incl. deps audit gate).

---
disable-model-invocation: true
---
# Procedure A — Incremental TDD

Execute the 8-step TDD workflow. Steps are sequential — do not skip.

1. SPEC     — Write `docs/spec/<module>.md`: inputs, outputs, edge cases
2. TEST     — Write a test in `tests/units/` (isolated, specific assertions). TDD prefers red-first — write it before the code so it fails on first run — but a test for already-implemented behavior that passes on first run is fine as long as it asserts something specific.
3. CODE     — Minimal code in `src/` to pass the test only
4. VERIFY   — Developer runs: `make test && make nonreg`
5. BASELINE — Capture output in `tests/data/<test_name>_expected.<ext>`
6. NONREG   — Promote validated test to `tests/nonreg/`
7. DOC      — Update `docs/spec/<module>.md` (same commit as code)
8. VERSION  — Bump VERSION: MAJOR=breaking · MINOR=feature · PATCH=fix/refactor

Rules:
- Fix code, not tests (unless spec was wrong)
- Baseline changes require justification + `CHANGELOG.md` entry
- Failing nonreg blocks the build — no override

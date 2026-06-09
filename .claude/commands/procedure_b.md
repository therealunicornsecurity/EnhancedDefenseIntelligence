---
disable-model-invocation: true
---
# Procedure B — Code Quality Review

Triggered by: `make review`
Steps are sequential. Each produces findings before proceeding.

0. DEPS      — Run `/deps_audit`: flag CVEs and license violations — BLOCKING
1. SPLIT     — Split any `src/` file > 1000 lines into submodules
2. DEDUP     — Find duplicated logic (>10 lines), copy-pasted blocks
3. LIBRARIES — Extract cross-repo duplicates into shared libraries
4. NAMING    — Enforce naming conventions (RULES.md §1)
5. FILES     — Verify repo structure; remove orphans and temp files
6. SECURITY  — Run BOTH `/security_scan` (grep RULES.md §5) and `/security_review`
               (AI semantic pass over the diff) — BLOCKING
7. REFACTOR  — Extract, rename, flatten nesting, remove dead code.
               Simplify cyclomatic complexity > 10. Use early returns.
8. OPTIMIZE  — Run `/perf_benchmark before` and `after`. Address: unnecessary
               allocations, N+1 queries, missing caches, sync ops that could
               be concurrent, oversized deps, resource leaks.

Claude does: analysis, reporting, code edits per Procedure A
Developer runs after each step: `make nonreg`

Rules:
- Every fix follows Procedure A (test before change)
- Claude never runs `make` — the developer validates with `make nonreg`
- A failing nonreg blocks progression to the next step

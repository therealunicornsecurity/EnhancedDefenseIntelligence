---
name: security_review
description: AI-powered, diff-scoped semantic security review — the deep complement to the grep-based /security_scan in Procedure B Step 6. Integrates anthropics/claude-code-security-review (MIT).
version: 1.0.0
tags: [security, review, ai, vulnerabilities, sast]
---

# /security_review

Semantic, context-aware security review of the **pending changes** (a diff), powered
by Claude. Where [`/security_scan`](../security_scan/SKILL.md) is a fast, deterministic
**grep** for the forbidden patterns in `RULES.md §5`, `/security_review` reasons about
the *meaning* of the change — taint flow, auth logic, injection sinks — and reports only
high-confidence findings.

> **Integrates [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review)** (MIT).
> Methodology (3-phase analysis, severity tiers, confidence scale, false-positive
> precedents) is adapted from that project; see **Attribution** below.

## Where it fits

Procedure B **Step 6 — SECURITY** runs two passes, fast → deep:

1. `/security_scan` — grep `RULES.md §5` + `docs/security.md`. **Blocking**, deterministic.
2. `/security_review` — this skill. Semantic pass over the diff for what grep can't see.

`/security_scan` stays the blocking gate; `/security_review` adds depth. A HIGH-severity,
≥0.8-confidence finding here is also treated as blocking.

## ⚠️ EDI constraint — git is blocked by the hook

EDI's `.claude/hooks/PreToolCall` refuses all `git` commands, but a diff review needs one.
So `/security_review` runs in one of two modes:

- **CI mode (recommended).** The GitHub Action runs `git diff` *in CI*, outside the hook.
  Enable `templates/security-review.yml` (synced to `.github/workflows/security-review.yml`)
  and set a `CLAUDE_API_KEY` repo secret. Reviews every PR, comments findings.
- **Interactive mode.** The agent cannot run `git`. The developer supplies the diff —
  `git diff main...HEAD > /tmp/review.diff` — and points the skill at it (or names the
  changed files). The skill reads those with `Read`/`Grep` and applies the methodology.

Never silently fall back to "scan the whole tree": review is **diff-scoped** by design.

## Security categories examined

Injection (SQL, command, LDAP, XPath, NoSQL, XXE) · auth & authz (broken auth, privilege
escalation, IDOR, session) · data exposure (hardcoded secrets, sensitive logging, PII) ·
crypto (weak algorithms, key management) · input validation · business-logic flaws (race
conditions, TOCTOU) · configuration (insecure defaults, missing headers, permissive CORS) ·
supply chain (vulnerable deps, typosquatting) · code execution (deserialization, pickle/eval) ·
XSS (reflected, stored, DOM).

## Analysis methodology (3 phases)

1. **Identify** — read the diff. For each change, ask what an attacker controls and where it
   flows. Flag concrete vulnerabilities with a source → sink path.
2. **Filter** — drop false positives (see precedents). No finding survives without a
   plausible exploit path.
3. **Report** — only findings at **confidence ≥ 0.7**, each with severity, confidence, the
   exact `file:line`, why it's exploitable, and a remediation.

## Severity guidelines

- **HIGH** — directly exploitable: RCE, data breach, authentication bypass.
- **MEDIUM** — significant impact but requires specific conditions.
- **LOW** — defense-in-depth / lower-impact issues.

## Confidence scale

- `0.9–1.0` — certain exploit path identified.
- `0.8–0.9` — clear vulnerability pattern with known exploitation.
- `0.7–0.8` — suspicious pattern, needs specific conditions.
- `< 0.7` — **do not report** (too speculative).

## False-positive filtering (precedents)

Do **not** report, absent a proven, triggerable impact: denial-of-service / resource
exhaustion (memory, CPU, disk), rate-limiting gaps, generic "missing input validation"
without a sink, open redirects, secrets stored on local disk by design, and input-sanitization
concerns in CI/GitHub-Action YAML unless clearly attacker-triggerable. Prefer false negatives
over noise — a wrong HIGH finding costs more trust than a missed LOW.

## Output format

```
## Security Review: <repo> — <diff range>
### Findings
- [HIGH · 0.92] src/<file>:<line> — <title>
  - Path: <source> → <sink>
  - Impact: <what an attacker achieves>
  - Fix: <concrete remediation>
- [MEDIUM · 0.81] ...
### Filtered (false positives)
- <pattern> — <why dropped>
### Verdict
- <N> findings (<H> HIGH / <M> MEDIUM / <L> LOW). HIGH·≥0.8 → Step 6 BLOCKING.
```

## CI integration (the GitHub Action form)

`templates/security-review.yml` wires the upstream Action on `pull_request`:

```yaml
- uses: anthropics/claude-code-security-review@main
  with:
    comment-pr: true
    claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
    # custom-security-scan-instructions: docs/security.md   # reuse EDI's per-language addendum
    # exclude-directories: tests,docs
```

Key inputs: `claude-api-key` (required), `comment-pr` (default `true`), `claude-model`
(default `claude-opus-4-1-20250805`), `exclude-directories`, `custom-security-scan-instructions`,
`false-positive-filtering-instructions`. Outputs: `findings-count`, `results-file`.

**Hardening note (from upstream):** the Action is *not* hardened against prompt injection.
Review trusted PRs only; enable "Require approval for all external contributors" on the repo.

## Rules

- Diff-scoped, not whole-tree. Confidence `< 0.7` is never reported.
- HIGH finding at confidence ≥ 0.8 blocks Procedure B Step 6 (same weight as a `/security_scan` hit).
- Report only — do not auto-fix. Each fix follows Procedure A (test first).
- Complements, never replaces, `/security_scan` — run both at Step 6.

## Attribution

Adapted from **[anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review)**,
licensed **MIT**. The upstream project supplies the GitHub Action (`action.yml`), the audit
engine (`claudecode/github_action_audit.py`, `prompts.py`, `findings_filter.py`), and the
original `/security-review` command this skill's methodology is derived from.

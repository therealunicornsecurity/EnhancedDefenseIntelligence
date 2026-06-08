---
name: security_scan
description: Grep src/ for the forbidden patterns listed in RULES.md §5 — Procedure B Step 6 gate (BLOCKING)
version: 1.0.0
tags: [security, scan, lint, review]
---

# /security_scan

Scan `src/` for the **forbidden code patterns** defined in `RULES.md §5` (universal, language-agnostic) **plus** the language-specific patterns at `docs/security.md` (copied from the kit's `templates/security/<lang>.md` at `edi.sh init`). Step 6 of the Code Quality Review (Procedure B). Any hit is **blocking** — fix before continuing.

Always grep both layers:
1. `RULES.md §5` — universal patterns (apply everywhere)
2. `docs/security.md` — language-specific patterns (Python / C / Rust / Go each have their own forbidden list, recommended idioms, secrets-handling rules, and secure-deletion guidance)

## The patterns (RULES.md §5)

| Forbidden | Why | Grep hint |
|-----------|-----|-----------|
| Hardcoded passwords, API keys, tokens | Use env vars or config files | `(password\|api[_-]?key\|token)\s*=\s*["'][^"']{8,}` |
| `eval()`, `exec()` with unsanitized input | Command injection | `\beval\s*\(\|\bexec\s*\(` |
| `os.system`, `subprocess(shell=True)` with user input | Command injection | `os\.system\\|shell\s*=\s*True` |
| String concatenation in SQL queries | SQL injection — use parameterized | `(SELECT\|INSERT\|UPDATE\|DELETE).*["'].*\+` |
| Unsanitized input in file paths | Path traversal | `open\s*\(.*\+\\|os\.path\.join\(.*input` |
| MD5 / SHA1 for security purposes | Weak crypto — use SHA-256+ | `md5\\|sha1` (review hits — file checksums are OK) |
| `pickle.loads()`, `yaml.load()` without SafeLoader | Insecure deserialization | `pickle\.loads\\|yaml\.load\s*\(` (without `SafeLoader`) |
| `http://` in production infrastructure code | Use HTTPS | `http://` (review hits — docs/links are OK) |
| `.env` files or private keys committed to git | Secrets leak | check `git ls-files` for `\.env\|\.key\|\.pem\|id_rsa` |
| `print()` for logging | Use a logging framework | `^\s*print\s*\(` |

## Procedure

1. Run each grep against `src/` (recursive, case-insensitive where appropriate)
2. For every hit: `file:line — pattern — snippet — explain why this fires`
3. Some patterns are dual-use (`md5` for checksums is fine; `http://` in a doc comment is fine). Mark those as **review** and let the developer decide. The rest are **block**.
4. Verify no secrets-named files are tracked: `git ls-files | grep -E '\.env$|\.key$|\.pem$|id_[rd]sa$|kubeconfig$|credentials\.json$'`

## Output Format

```
## Security Scan: <repo>
### Blocking
- src/<file>:<line> — <pattern> — <snippet>
### Review (likely false positive)
- src/<file>:<line> — <pattern> — <snippet> — <why dual-use>
### Tracked secret-named files (BLOCKING)
- <file>
### Clean
- <N> files scanned, no issues
```

## Rules

- Blocking hits stop Procedure B at Step 6.
- Mark legitimate exceptions in the source with a justified comment: `# SECURITY-EXEMPT: <reason>`.
- Do not auto-fix — report only. The developer decides each case.
- This skill greps for the listed patterns. Deeper analysis (taint flow, control flow) is out of scope — pair with a language-specific SAST tool if you need that depth.

---
name: deps_audit
description: Dependency CVE scan and license compliance check — review procedure gate (step 0)
version: 1.0.0
tags: [security, dependencies, licenses, cve]
---

# /deps_audit

Audit declared dependencies for CVEs and license violations. Runs as Step 0 of the Code Quality Review.

## Checks

### CVE Scan
- Parse dependency manifest (`requirements.txt`, `go.mod`, `package.json`, `Cargo.toml`, etc.)
- Flag any package with a known CVE at the declared version
- Severity threshold: MEDIUM and above are blocking

### License Compliance
- Identify declared licenses for each dependency
- Flag: GPL, AGPL, SSPL — incompatible with proprietary use unless explicit approval
- Warn: LGPL, MPL — review required
- Pass: MIT, Apache-2.0, BSD-*, ISC, Unlicense

### Version Hygiene
- Flag dependencies pinned to a range (`^`, `~`, `>=`) in production manifests
- Flag packages with no declared version

## Output Format

```
## Deps Audit: <manifest file>
### Blocking CVEs
- <package>@<version> — CVE-YYYY-NNNNN (CRITICAL/HIGH/MEDIUM) — description
### License Violations
- <package> — <license> — reason blocked
### Warnings
- <package> — reason
### Clean
- <N> packages, no issues found
```

## Rules
- Blocking CVEs and license violations stop the review at Step 0
- Resolution: pin to patched version or add justified exemption comment
- Do not auto-update versions — report only, the developer decides

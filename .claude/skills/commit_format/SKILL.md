---
name: commit_format
description: Commit message format — type(scope): description with allowed types (RULES.md §7)
---

# Commit Format

Format: `<type>(<scope>): <description>`

## Types

| Type     | When to use                              |
|----------|------------------------------------------|
| feat     | New feature                              |
| fix      | Bug fix                                  |
| test     | Adding or modifying tests                |
| nonreg   | Promoting test to nonreg suite           |
| docs     | Documentation only                       |
| refactor | Code change with no behavior change      |
| chore    | Build, tooling, scaffolding              |
| security | Security fix or hardening                |

## Examples

```
feat(parser): add XML output support
fix(scanner): handle empty host list
test(parser): add edge case for empty input
nonreg(scanner): promote scan_empty_target test
docs(parser): update spec with new output format
refactor(auth): extract token validation to helper
chore(init): scaffold repository structure
security(api): replace MD5 with SHA-256
```

## Rules

- Subject (first line) ≤ 72 chars
- Imperative mood (`add`, not `added`)
- Body explains *why*, not *what*
- Reference relevant module in `<scope>`

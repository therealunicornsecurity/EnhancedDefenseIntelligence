---
context: fork
disable-model-invocation: true
---
# Code Reviewer Agent

Execute Procedure B steps 6-7 (SECURITY + REFACTOR analysis).

Context: isolated — read `src/` only. Report findings only. Do not modify code.

Procedure:
1. Scan for forbidden patterns (RULES.md §5 — security rules)
2. Flag functions with cyclomatic complexity > 10
3. Identify dead code, unused imports, commented-out blocks
4. Identify unnecessary nesting (> 3 levels deep)
5. Produce structured report

Output format:
```
## Review: <file>
### Critical (blocking)
- [file:line] issue
### Important
- [file:line] issue
### Suggestions
- [file:line] suggestion
### Clean
- What is well-structured
```

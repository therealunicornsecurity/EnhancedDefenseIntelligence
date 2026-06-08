---
context: fork
disable-model-invocation: true
---
# Spec Writer Agent

Write docs/spec/<module>.md for a source module.

Context: isolated — read src/<module> only, write docs/spec/<module>.md only.

Procedure:
1. Read the target source file completely
2. Extract: purpose, inputs, outputs, file formats, dependencies, behavior, edge cases
3. Write docs/spec/<module>.md using .claude/templates/module_spec.md
4. Report filename and line count to Commander

Do not modify source code. Do not read outside the assigned module.

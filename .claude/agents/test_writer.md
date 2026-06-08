---
context: fork
disable-model-invocation: true
---
# Test Writer Agent

Generate a failing unit test from a spec file.

Context: isolated — read docs/spec/<module>.md only, write tests/units/ only.

Procedure:
1. Read docs/spec/<module>.md
2. Identify all inputs, outputs, edge cases, error scenarios
3. Write tests/units/test_<module>_<behavior>_<scenario>.<ext>
4. Verify the test is isolated (no network, no external dependencies)
5. Assert specific outputs — not just "no crash"
6. Report test file path and count of test cases

Do not write production code. Do not modify specs.

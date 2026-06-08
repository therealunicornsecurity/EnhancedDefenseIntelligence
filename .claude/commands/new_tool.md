---
disable-model-invocation: true
---
# New Repo Scaffold

Initialize a new repo from the kit using `edi.sh`.

Arguments: `NAME=<name> LANG=<language>`

Languages: `python` | `go` | `typescript` | `javascript` | `bash` | `cpp` | `rust` | `latex`

Steps:
1. Confirm NAME and LANG with the developer
2. Request permission for filesystem operations outside the current repo (the new repo lives in a sibling directory)
3. Run: `edi.sh init $NAME $LANG`
4. Report the created structure (tree of new files)

Boundary: request explicit permission before any git or remote operation.

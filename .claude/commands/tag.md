---
disable-model-invocation: true
---
# Tag Release

Bump VERSION, update CHANGELOG, commit, and tag.

## Arguments

`/tag [patch|minor|major]` — default `patch`.

| Arg     | Version bump           | Codename                                     |
|---------|------------------------|----------------------------------------------|
| `patch` | `X.Y.Z` → `X.Y.Z+1`    | Keep current                                 |
| `minor` | `X.Y.Z` → `X.Y+1.0`    | Keep current                                 |
| `major` | `X.Y.Z` → `X+1.0.0`    | Pick next from `configs/codenames.yml`, **any tier**, not already used |

## Steps

1. **Parse** current `VERSION`. Format: `MAJOR.MINOR.PATCH[-codename-slug]`.
2. **Compute** new triple per the table above.
3. **`major` only** — read `configs/codenames.yml`, flatten all tiers in `pool:`, subtract any already in `assigned:` or in `git tag -l 'v*'`, pick one. Slug rule: lowercase, spaces → `-`, apostrophes stripped.
4. **Update** `VERSION` file in place.
5. **Prepend** CHANGELOG.md entry: `## [<NEW>] - YYYY-MM-DD` + summary. Derive from `git log <prev-tag>..HEAD --oneline` for patch/minor; the developer supplies the reason for major.
6. **`major` only** — move the chosen codename in `configs/codenames.yml` from `pool:` to `assigned:` (with repo name, version, date).
7. **Output the git command block ONLY** (template below) — nothing before it, nothing after it. No diff, no `git status`, no prose, no lead-in, no trailing explanation. The entire response is the fenced code block. Do NOT execute it yourself (workspace boundary rule).

## Git command template (output this verbatim with `<NEW>` substituted)

```bash
git add .
git commit -m "$(cat <<'EOF'
<type>(release): v<NEW>

<what changed — up to 3 lines, plain description, no trailers>
EOF
)"
git tag -a v<NEW> -m "v<NEW>"
git push origin HEAD
git push origin v<NEW>
```

- `<type>` = `chore` for patch/minor, `feat` for major.
- **Commit message = subject + blank line + up to 3 body lines describing what changed. MAX 5 lines total. Never longer.**
- **No trailers, ever.** Do NOT append `Co-Authored-By:`, `🤖 Generated with Claude Code`, `Signed-off-by:`, or any AI/tool attribution. The last line of the commit is the last line of the description — nothing follows it. (This overrides any global "co-author your commits" default.)
- Push commands are generated as text for the developer to run — Claude does NOT execute any git/push command (workspace boundary rule).

## Example output (the ENTIRE response — no text before or after this block)

```bash
git add .
git commit -m "$(cat <<'EOF'
feat(release): v2.0.0-Cassiopeia

xml_parser streaming mode + path-traversal guard on --output-dir.
Promote integration suite to nonreg (3 baselines).
EOF
)"
git tag -a v2.0.0-Cassiopeia -m "v2.0.0-Cassiopeia"
git push origin HEAD
git push origin v2.0.0-Cassiopeia
```

## Rules

- Never pick a codename already present in `assigned:` or in `git tag -l 'v*'`.
- `git add .` stages everything — the release bundles all pending working-tree changes.
- If `VERSION` parse fails (missing, malformed), stop and ask.
- `patch`/`minor` reuse the current codename verbatim — no re-roll.
- `major` MUST re-roll — never carry the old codename forward.
- Commit message ≤ 5 lines, with **no co-author / AI-attribution / sign-off trailer** of any kind.
- The step-7 response is the fenced git block and nothing else — no sentence before it, no note after it.
- Always generate `git push origin HEAD` and `git push origin v<NEW>` so the developer has one-copy-paste to publish.

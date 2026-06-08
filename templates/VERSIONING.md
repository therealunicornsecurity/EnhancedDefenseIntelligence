# Versioning Scheme

## Universal Version Format

Every repo built from this kit uses the same version format:

```
<MAJOR>.<MINOR>.<PATCH>[-<CODENAME>]
```

### Components

| Part | Meaning | When to bump | Example |
|------|---------|--------------|---------|
| **MAJOR** | Breaking changes to inputs, outputs, or behavior | API/schema contract breaks, incompatible changes | `2.0.0` |
| **MINOR** | New features, backward-compatible | New module, new output field, new feature | `1.3.0` |
| **PATCH** | Bug fixes, small improvements | Fix, refactor, doc update, nonreg addition | `1.3.7` |
| **CODENAME** | Release name (from `configs/codenames.yml`) | Assigned at each MINOR or MAJOR release | `Andromeda` |

### Rules

1. **PATCH** versions have no codename — they are numeric only (`1.3.7`)
2. **MINOR** and **MAJOR** releases receive a codename (`1.3.0-Andromeda`)
3. Codenames are drawn from `configs/codenames.yml` (copied from the kit at init/update time)
4. Each repo has its own independent version number
5. Each repo draws from the **same shared codename pool** — no two releases across any repo share a codename
6. Once a codename is assigned, it is permanently consumed (moved to `assigned:` in `codenames.yml`)
7. Tier 1 codenames are reserved for MAJOR releases
8. Tier 2 codenames are for MINOR releases
9. Tier 3/4 codenames are overflow — used when higher tiers are exhausted

### Examples

```
parser     1.0.0-Orion         # first major release
parser     1.0.1               # patch, no codename
parser     1.0.2               # another patch
parser     1.1.0-Andromeda     # new feature release
parser     1.1.1               # patch
scanner    1.0.0-Cassiopeia    # scanner's first major
runner     2.0.0-Cygnus        # runner breaking change
```

### VERSION File

Every repo contains a `VERSION` file at the root with a single line:

```
1.3.0-Andromeda
```

For patch versions (no codename):

```
1.3.7
```

### CHANGELOG.md Integration

```markdown
## [1.3.0-Andromeda] - 2026-04-15
### Added
- Feature X

## [1.2.5] - 2026-04-10
### Fixed
- Bug Y
```

### Codename Assignment Process

1. The developer (or AI) decides a release warrants MINOR or MAJOR bump
2. Check `configs/codenames.yml` for next available codename in the appropriate tier
3. Assign codename to the release
4. Move codename to `assigned:` section with repo name, version, and date
5. Update `VERSION` file in the repo
6. Update `CHANGELOG.md`

The `/tag` slash command automates this — see `.claude/commands/tag.md`.

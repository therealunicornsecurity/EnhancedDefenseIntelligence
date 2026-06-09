#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# edi.sh — EDI scaffolder + sync tool
# ═══════════════════════════════════════════════════════════════════════
# Usage:
#   edi.sh init <name> <language>       Scaffold a new repo from this kit
#   edi.sh update                       Re-sync Tier-1 (Law) files
#   edi.sh comply                       Check current repo against the rules
#   edi.sh help                         Show this help
#
# Languages: python | go | typescript | javascript | bash | cpp | rust | latex
#
# Tier system (RULES.md §10):
#   Tier 1 — Law      : force-sync from kit, local edits lost on `update`
#   Tier 2 — Scaffold : written at init only, never overwritten
#   Tier 3 — Merge    : added if missing, kept if present
#   Tier 4 — Local    : never touched
#
# Flags: T=template-substitute ({{TOOL_NAME}}, {{LANGUAGE}})
#        R=read-only after sync (chmod 0444)
#        X=executable after sync (chmod +x — hooks, scripts)
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

# Find kit root (the directory of this script)
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD=$(tput bold); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1); BLUE=$(tput setaf 4); NC=$(tput sgr0)
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; BLUE=""; NC=""
fi

header()  { printf "\n${BOLD}%s${NC}\n" "$1"; }
ok()      { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
warn()    { printf "  ${YELLOW}!${NC} %s\n" "$1"; }
err()     { printf "  ${RED}✗${NC} %s\n" "$1" >&2; }
info()    { printf "  ${BLUE}·${NC} %s\n" "$1"; }

# ─── Sync manifest ────────────────────────────────────────────────────
# Format: <kit-relative-path>|<repo-relative-path>|<tier>|<flags>
# Flags: T=template-substitute, R=read-only after sync
SYNC_MANIFEST=(
    "templates/RULES.md|RULES.md|1|T"
    "templates/CLAUDE.md|.claude/CLAUDE.md|1|T"
    "templates/Makefile|Makefile|2|T"
    "templates/VERSIONING.md|docs/VERSIONING.md|1|"
    "templates/codenames-example.yml|configs/codenames.yml|2|"
    ".claude/commands/tag.md|.claude/commands/tag.md|1|"
    ".claude/commands/freeze.md|.claude/commands/freeze.md|1|"
    ".claude/commands/new_tool.md|.claude/commands/new_tool.md|1|"
    ".claude/commands/procedure_a.md|.claude/commands/procedure_a.md|1|"
    ".claude/commands/procedure_b.md|.claude/commands/procedure_b.md|1|"
    ".claude/skills/commit_format/SKILL.md|.claude/skills/commit_format/SKILL.md|1|"
    ".claude/skills/review/SKILL.md|.claude/skills/review/SKILL.md|1|"
    ".claude/skills/refactor/SKILL.md|.claude/skills/refactor/SKILL.md|1|"
    ".claude/skills/test_gen/SKILL.md|.claude/skills/test_gen/SKILL.md|1|"
    ".claude/skills/perf_benchmark/SKILL.md|.claude/skills/perf_benchmark/SKILL.md|1|"
    ".claude/skills/deps_audit/SKILL.md|.claude/skills/deps_audit/SKILL.md|1|"
    ".claude/skills/security_scan/SKILL.md|.claude/skills/security_scan/SKILL.md|1|"
    ".claude/skills/security_review/SKILL.md|.claude/skills/security_review/SKILL.md|1|"
    ".claude/agents/spec_writer.md|.claude/agents/spec_writer.md|3|"
    ".claude/agents/test_writer.md|.claude/agents/test_writer.md|3|"
    ".claude/agents/code_reviewer.md|.claude/agents/code_reviewer.md|3|"
    ".claude/templates/module_spec.md|.claude/templates/module_spec.md|1|"
    ".claude/hooks/PreToolCall|.claude/hooks/PreToolCall|1|X"
    ".claude/hooks/PostToolCall|.claude/hooks/PostToolCall|1|X"
    ".claude/hooks/Stop|.claude/hooks/Stop|1|X"
    ".claude/hooks/Notification|.claude/hooks/Notification|1|X"
    ".claude/settings.json|.claude/settings.json|3|"
    "templates/security-review.yml|.github/workflows/security-review.yml|3|"
)

# ─── Helpers ──────────────────────────────────────────────────────────

substitute_template() {
    local src="$1" dst="$2" name="$3" lang="$4"
    sed -e "s|{{TOOL_NAME}}|$name|g" \
        -e "s|{{LANGUAGE}}|$lang|g" \
        "$src" > "$dst"
}

sync_entry() {
    local src_rel="$1" dst_rel="$2" tier="$3" flags="$4" mode="$5" name="$6" lang="$7"
    local src="$KIT_ROOT/$src_rel"
    local dst="$dst_rel"

    [ -f "$src" ] || { warn "kit source missing: $src_rel"; return; }

    # Tier 2 + file exists + update mode → skip (init-only, force-protected)
    if [ "$tier" = "2" ] && [ -f "$dst" ] && [ "$mode" = "update" ]; then
        info "skipped (scaffold, exists): $dst_rel"
        return
    fi

    # Tier 3 + file exists → skip (merge-if-missing semantics)
    if [ "$tier" = "3" ] && [ -f "$dst" ]; then
        info "skipped (merge, exists): $dst_rel"
        return
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ "$flags" == *T* ]]; then
        substitute_template "$src" "$dst" "$name" "$lang"
    else
        cp "$src" "$dst"
    fi

    if [[ "$flags" == *R* ]]; then
        chmod 0444 "$dst" 2>/dev/null || true
    fi
    if [[ "$flags" == *X* ]]; then
        chmod +x "$dst" 2>/dev/null || true
    fi

    ok "synced: $dst_rel (tier $tier)"
}

# ─── Per-language security patterns ───────────────────────────────────
# Copies templates/security/<lang>.md → docs/security.md (Tier 1).
# Forbidden patterns + recommended idioms + secrets handling + secure
# deletion + tooling for the chosen language. The repo's `/security_scan`
# skill greps for the forbidden patterns listed here.

sync_security_patterns() {
    local lang="$1"
    local src="$KIT_ROOT/templates/security/$lang.md"
    local dst="docs/security.md"
    mkdir -p docs
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        ok "synced: $dst (from templates/security/$lang.md)"
    else
        warn "no security patterns template for language: $lang (consider contributing one)"
        cat > "$dst" <<EOF
# Security Patterns — $lang

No language-specific patterns shipped with this kit for \`$lang\`.
The universal rules in \`RULES.md §5\` still apply. Consider contributing
a \`templates/security/$lang.md\` upstream.
EOF
    fi
}

# ─── Commands ─────────────────────────────────────────────────────────

cmd_init() {
    local name="${1:-}" lang="${2:-}"
    if [ -z "$name" ] || [ -z "$lang" ]; then
        err "usage: edi.sh init <name> <language>"
        exit 1
    fi

    if [ -d "$name" ]; then
        err "directory already exists: $name"
        exit 1
    fi

    header "Scaffolding $name ($lang)"

    mkdir -p "$name"/{src,tests/{data,units,nonreg,integration},docs/{spec,roadmap},snapshots,configs,.claude/{commands,skills,agents,templates,hooks,docs}}
    cd "$name"

    # Sync all manifest entries (init mode → no skips for Tier 2)
    for entry in "${SYNC_MANIFEST[@]}"; do
        IFS='|' read -r src dst tier flags <<<"$entry"
        sync_entry "$src" "$dst" "$tier" "$flags" "init" "$name" "$lang"
    done

    # Per-language .gitignore
    local gi="$KIT_ROOT/templates/gitignore.$lang"
    if [ -f "$gi" ]; then
        cp "$gi" .gitignore
        ok "synced: .gitignore (from gitignore.$lang)"
    else
        warn "no gitignore template for language: $lang"
        : > .gitignore
    fi

    # Per-language security patterns (Tier 1 — force-synced from kit on update)
    sync_security_patterns "$lang"

    # Record language for edi.sh update to find later
    echo "$lang" > .kit-lang

    # VERSION + CHANGELOG (Tier 2 — scaffold once)
    local codename
    codename=$(grep -E '^\s+-\s' "$KIT_ROOT/templates/codenames-example.yml" | head -1 | awk '{print $2}')
    echo "0.1.0-${codename:-Initial}" > VERSION
    sed -e "s|{{TOOL_NAME}}|$name|g" \
        -e "s|{{CODENAME}}|${codename:-Initial}|g" \
        -e "s|YYYY-MM-DD|$(date +%Y-%m-%d)|" \
        "$KIT_ROOT/templates/CHANGELOG.template.md" > CHANGELOG.md
    ok "synced: VERSION, CHANGELOG.md"

    header "Done. Next steps:"
    info "  cd $name"
    info "  git init && git add . && git commit -m 'chore(init): scaffold $name'"
    info "  read RULES.md before writing any code"
}

cmd_update() {
    header "Updating Tier-1 (Law) + Tier-3 (Merge) files from kit at $KIT_ROOT"

    if [ ! -f RULES.md ]; then
        err "not in a kit-scaffolded repo (no RULES.md). Run from the repo root."
        exit 1
    fi

    # Detect repo name from RULES.md (best-effort)
    local name lang
    name=$(basename "$(pwd)")
    lang="$(cat .kit-lang 2>/dev/null || echo unknown)"

    for entry in "${SYNC_MANIFEST[@]}"; do
        IFS='|' read -r src dst tier flags <<<"$entry"
        sync_entry "$src" "$dst" "$tier" "$flags" "update" "$name" "$lang"
    done

    # Re-sync per-language security patterns (Tier 1)
    if [ "$lang" != "unknown" ]; then
        sync_security_patterns "$lang"
    else
        warn "no .kit-lang file — skipping per-language security patterns sync"
    fi

    ok "update complete"
}

cmd_comply() {
    header "Compliance check"
    local fail=0

    [ -f RULES.md ]            || { err "missing: RULES.md (Tier 1)"; fail=1; }
    [ -f .claude/CLAUDE.md ]   || { err "missing: .claude/CLAUDE.md (Tier 1)"; fail=1; }
    [ -f VERSION ]             || { err "missing: VERSION (Tier 2)"; fail=1; }
    [ -f CHANGELOG.md ]        || { err "missing: CHANGELOG.md (Tier 2)"; fail=1; }
    [ -f Makefile ]            || { err "missing: Makefile (Tier 2)"; fail=1; }
    [ -d src ]                 || { err "missing: src/ (RULES.md §1)"; fail=1; }
    [ -d tests/units ]         || { err "missing: tests/units/ (RULES.md §1)"; fail=1; }
    [ -d docs/spec ]           || { err "missing: docs/spec/ (RULES.md §1)"; fail=1; }
    [ -f docs/index.md ]       || { err "missing: docs/index.md (RULES.md §2)"; fail=1; }

    # Files > 1000 lines
    if [ -d src ]; then
        while IFS= read -r f; do
            local n
            n=$(wc -l < "$f")
            if [ "$n" -gt 1000 ]; then
                err "file > 1000 lines: $f ($n) — split required (RULES.md §4 step 1)"
                fail=1
            fi
        done < <(find src -type f 2>/dev/null)
    fi

    [ "$fail" = "0" ] && ok "all checks passed" || err "compliance check failed"
    return $fail
}

cmd_help() {
    sed -n '2,/^# ═══*$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ─── Main ─────────────────────────────────────────────────────────────

cmd="${1:-help}"
shift || true

case "$cmd" in
    init)    cmd_init "$@" ;;
    update)  cmd_update "$@" ;;
    comply)  cmd_comply "$@" ;;
    help|-h|--help) cmd_help ;;
    *)       err "unknown command: $cmd"; cmd_help; exit 1 ;;
esac

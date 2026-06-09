#!/usr/bin/env pwsh
# ═══════════════════════════════════════════════════════════════════════
# edi.ps1 — EDI scaffolder + sync tool  (PowerShell port of edi.sh)
# ═══════════════════════════════════════════════════════════════════════
# Usage:
#   edi.ps1 init <name> <language>       Scaffold a new repo from this kit
#   edi.ps1 update                       Re-sync Tier-1 (Law) files
#   edi.ps1 comply                       Check current repo against the rules
#   edi.ps1 help                         Show this help
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
#        R=read-only after sync
#        X=executable after sync (chmod +x — Unix only)
#
# Runs on PowerShell 7+ (pwsh). On Windows PowerShell 5.1, save this file
# as UTF-8 with BOM so the box-drawing/glyph characters parse correctly.
# ═══════════════════════════════════════════════════════════════════════

[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command = 'help',
    [Parameter(Position = 1)][string]$Arg1,
    [Parameter(Position = 2)][string]$Arg2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Find kit root (the directory of this script)
$KitRoot = $PSScriptRoot

# UTF-8 without BOM — matches what `>` / `cp` produce on Unix
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ─── Output helpers ───────────────────────────────────────────────────
function Write-Header { param([string]$m) Write-Host ''; Write-Host $m -ForegroundColor White }
function Write-Ok     { param([string]$m) Write-Host "  $([char]0x2713) $m" -ForegroundColor Green }   # ✓
function Write-Warn   { param([string]$m) Write-Host "  ! $m"               -ForegroundColor Yellow }   # !
function Write-Err    { param([string]$m) Write-Host "  $([char]0x2717) $m" -ForegroundColor Red }      # ✗
function Write-Info   { param([string]$m) Write-Host "  $([char]0x00B7) $m" -ForegroundColor Blue }     # ·

# ─── Sync manifest ────────────────────────────────────────────────────
# Format: <kit-relative-path>|<repo-relative-path>|<tier>|<flags>
# Flags: T=template-substitute, R=read-only, X=executable after sync
$SyncManifest = @(
    'templates/RULES.md|RULES.md|1|T'
    'templates/CLAUDE.md|.claude/CLAUDE.md|1|T'
    'templates/Makefile|Makefile|2|T'
    'templates/VERSIONING.md|docs/VERSIONING.md|1|'
    'templates/codenames-example.yml|configs/codenames.yml|2|'
    '.claude/commands/tag.md|.claude/commands/tag.md|1|'
    '.claude/commands/freeze.md|.claude/commands/freeze.md|1|'
    '.claude/commands/new_tool.md|.claude/commands/new_tool.md|1|'
    '.claude/commands/procedure_a.md|.claude/commands/procedure_a.md|1|'
    '.claude/commands/procedure_b.md|.claude/commands/procedure_b.md|1|'
    '.claude/skills/commit_format/SKILL.md|.claude/skills/commit_format/SKILL.md|1|'
    '.claude/skills/review/SKILL.md|.claude/skills/review/SKILL.md|1|'
    '.claude/skills/refactor/SKILL.md|.claude/skills/refactor/SKILL.md|1|'
    '.claude/skills/test_gen/SKILL.md|.claude/skills/test_gen/SKILL.md|1|'
    '.claude/skills/perf_benchmark/SKILL.md|.claude/skills/perf_benchmark/SKILL.md|1|'
    '.claude/skills/deps_audit/SKILL.md|.claude/skills/deps_audit/SKILL.md|1|'
    '.claude/skills/security_scan/SKILL.md|.claude/skills/security_scan/SKILL.md|1|'
    '.claude/skills/security_review/SKILL.md|.claude/skills/security_review/SKILL.md|1|'
    '.claude/agents/spec_writer.md|.claude/agents/spec_writer.md|3|'
    '.claude/agents/test_writer.md|.claude/agents/test_writer.md|3|'
    '.claude/agents/code_reviewer.md|.claude/agents/code_reviewer.md|3|'
    '.claude/templates/module_spec.md|.claude/templates/module_spec.md|1|'
    '.claude/hooks/PreToolCall|.claude/hooks/PreToolCall|1|X'
    '.claude/hooks/PostToolCall|.claude/hooks/PostToolCall|1|X'
    '.claude/hooks/Stop|.claude/hooks/Stop|1|X'
    '.claude/hooks/Notification|.claude/hooks/Notification|1|X'
    '.claude/settings.json|.claude/settings.json|3|'
    'templates/security-review.yml|.github/workflows/security-review.yml|3|'
)

# ─── Helpers ──────────────────────────────────────────────────────────

function Write-TextFile {
    param([string]$Path, [string]$Content)
    $full = if ([System.IO.Path]::IsPathRooted($Path)) { $Path }
            else { Join-Path (Get-Location).ProviderPath $Path }
    [System.IO.File]::WriteAllText($full, $Content, $Utf8NoBom)
}

function Invoke-SubstituteTemplate {
    param([string]$Src, [string]$Dst, [string]$Name, [string]$Lang)
    $content = [System.IO.File]::ReadAllText($Src)
    $content = $content.Replace('{{TOOL_NAME}}', $Name).Replace('{{LANGUAGE}}', $Lang)
    Write-TextFile -Path $Dst -Content $content
}

function Set-ExecutableBit {
    param([string]$Path)
    # Executable bit only matters on Unix; on Windows it's a no-op.
    if ($PSVersionTable.PSVersion.Major -ge 6 -and ($IsLinux -or $IsMacOS)) {
        try { & chmod +x $Path 2>$null } catch { }
    }
}

function Sync-Entry {
    param([string]$SrcRel, [string]$DstRel, [string]$Tier, [string]$Flags,
          [string]$Mode, [string]$Name, [string]$Lang)

    $src = Join-Path $KitRoot $SrcRel
    $dst = $DstRel

    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Warn "kit source missing: $SrcRel"; return
    }

    # Tier 2 + file exists + update mode → skip (init-only, force-protected)
    if ($Tier -eq '2' -and (Test-Path -LiteralPath $dst) -and $Mode -eq 'update') {
        Write-Info "skipped (scaffold, exists): $DstRel"; return
    }

    # Tier 3 + file exists → skip (merge-if-missing semantics)
    if ($Tier -eq '3' -and (Test-Path -LiteralPath $dst)) {
        Write-Info "skipped (merge, exists): $DstRel"; return
    }

    $dir = Split-Path -Parent $dst
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    if ($Flags -like '*T*') {
        Invoke-SubstituteTemplate -Src $src -Dst $dst -Name $Name -Lang $Lang
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }

    if ($Flags -like '*R*') {
        try { Set-ItemProperty -LiteralPath $dst -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue } catch { }
    }
    if ($Flags -like '*X*') {
        Set-ExecutableBit $dst
    }

    Write-Ok "synced: $DstRel (tier $Tier)"
}

# ─── Per-language security patterns ───────────────────────────────────
# Copies templates/security/<lang>.md → docs/security.md (Tier 1).
function Sync-SecurityPatterns {
    param([string]$Lang)
    $src = Join-Path $KitRoot "templates/security/$Lang.md"
    $dst = 'docs/security.md'
    if (-not (Test-Path -LiteralPath 'docs')) { New-Item -ItemType Directory -Force -Path 'docs' | Out-Null }
    if (Test-Path -LiteralPath $src -PathType Leaf) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Ok "synced: $dst (from templates/security/$Lang.md)"
    } else {
        Write-Warn "no security patterns template for language: $Lang (consider contributing one)"
        $stub = @'
# Security Patterns — {0}

No language-specific patterns shipped with this kit for `{0}`.
The universal rules in `RULES.md §5` still apply. Consider contributing
a `templates/security/{0}.md` upstream.
'@ -f $Lang
        Write-TextFile -Path $dst -Content ($stub + "`n")
    }
}

# ─── Codename lookup (first entry in the pool) ────────────────────────
function Get-Codename {
    $f = Join-Path $KitRoot 'templates/codenames-example.yml'
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { return '' }
    foreach ($line in [System.IO.File]::ReadAllLines($f)) {
        if ($line -match '^\s+-\s+(\S+)') { return $Matches[1] }
    }
    return ''
}

# ─── Commands ─────────────────────────────────────────────────────────

function Invoke-Init {
    param([string]$Name, [string]$Lang)

    if ([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($Lang)) {
        Write-Err 'usage: edi.ps1 init <name> <language>'; exit 1
    }
    if (Test-Path -LiteralPath $Name) {
        Write-Err "directory already exists: $Name"; exit 1
    }

    Write-Header "Scaffolding $Name ($Lang)"

    $subdirs = @(
        'src',
        'tests/data', 'tests/units', 'tests/nonreg', 'tests/integration',
        'docs/spec', 'docs/roadmap',
        'snapshots', 'configs',
        '.claude/commands', '.claude/skills', '.claude/agents',
        '.claude/templates', '.claude/hooks', '.claude/docs'
    )
    foreach ($d in $subdirs) {
        New-Item -ItemType Directory -Force -Path (Join-Path $Name $d) | Out-Null
    }

    Push-Location $Name
    try {
        # Sync all manifest entries (init mode → no skips for Tier 2)
        foreach ($entry in $SyncManifest) {
            $p = $entry -split '\|'
            Sync-Entry -SrcRel $p[0] -DstRel $p[1] -Tier $p[2] -Flags $p[3] `
                       -Mode 'init' -Name $Name -Lang $Lang
        }

        # Per-language .gitignore
        $gi = Join-Path $KitRoot "templates/gitignore.$Lang"
        if (Test-Path -LiteralPath $gi -PathType Leaf) {
            Copy-Item -LiteralPath $gi -Destination '.gitignore' -Force
            Write-Ok "synced: .gitignore (from gitignore.$Lang)"
        } else {
            Write-Warn "no gitignore template for language: $Lang"
            Write-TextFile -Path '.gitignore' -Content ''
        }

        # Per-language security patterns (Tier 1 — force-synced on update)
        Sync-SecurityPatterns -Lang $Lang

        # Record language for edi.ps1 update to find later
        Write-TextFile -Path '.kit-lang' -Content ($Lang + "`n")

        # VERSION + CHANGELOG (Tier 2 — scaffold once)
        $codename = Get-Codename
        if ([string]::IsNullOrEmpty($codename)) { $codename = 'Initial' }
        Write-TextFile -Path 'VERSION' -Content ("0.1.0-$codename" + "`n")

        $today = Get-Date -Format 'yyyy-MM-dd'
        $clSrc = Join-Path $KitRoot 'templates/CHANGELOG.template.md'
        $cl = [System.IO.File]::ReadAllText($clSrc)
        $cl = $cl.Replace('{{TOOL_NAME}}', $Name).Replace('{{CODENAME}}', $codename).Replace('YYYY-MM-DD', $today)
        Write-TextFile -Path 'CHANGELOG.md' -Content $cl
        Write-Ok 'synced: VERSION, CHANGELOG.md'

        Write-Header 'Done. Next steps:'
        Write-Info "  cd $Name"
        Write-Info "  git init && git add . && git commit -m 'chore(init): scaffold $Name'"
        Write-Info '  read RULES.md before writing any code'
    } finally {
        Pop-Location
    }
}

function Invoke-Update {
    Write-Header "Updating Tier-1 (Law) + Tier-3 (Merge) files from kit at $KitRoot"

    if (-not (Test-Path -LiteralPath 'RULES.md' -PathType Leaf)) {
        Write-Err 'not in a kit-scaffolded repo (no RULES.md). Run from the repo root.'; exit 1
    }

    $name = Split-Path -Leaf (Get-Location).ProviderPath
    $lang = if (Test-Path -LiteralPath '.kit-lang' -PathType Leaf) {
        ([System.IO.File]::ReadAllText((Resolve-Path -LiteralPath '.kit-lang').ProviderPath)).Trim()
    } else { 'unknown' }

    foreach ($entry in $SyncManifest) {
        $p = $entry -split '\|'
        Sync-Entry -SrcRel $p[0] -DstRel $p[1] -Tier $p[2] -Flags $p[3] `
                   -Mode 'update' -Name $name -Lang $lang
    }

    if ($lang -ne 'unknown') {
        Sync-SecurityPatterns -Lang $lang
    } else {
        Write-Warn 'no .kit-lang file — skipping per-language security patterns sync'
    }

    Write-Ok 'update complete'
}

function Invoke-Comply {
    Write-Header 'Compliance check'
    $fail = 0

    $checks = @(
        @{ Path = 'RULES.md';         Type = 'Leaf';      Msg = 'missing: RULES.md (Tier 1)' }
        @{ Path = '.claude/CLAUDE.md'; Type = 'Leaf';      Msg = 'missing: .claude/CLAUDE.md (Tier 1)' }
        @{ Path = 'VERSION';          Type = 'Leaf';      Msg = 'missing: VERSION (Tier 2)' }
        @{ Path = 'CHANGELOG.md';     Type = 'Leaf';      Msg = 'missing: CHANGELOG.md (Tier 2)' }
        @{ Path = 'Makefile';         Type = 'Leaf';      Msg = 'missing: Makefile (Tier 2)' }
        @{ Path = 'src';              Type = 'Container'; Msg = 'missing: src/ (RULES.md §1)' }
        @{ Path = 'tests/units';      Type = 'Container'; Msg = 'missing: tests/units/ (RULES.md §1)' }
        @{ Path = 'docs/spec';        Type = 'Container'; Msg = 'missing: docs/spec/ (RULES.md §1)' }
        @{ Path = 'docs/index.md';    Type = 'Leaf';      Msg = 'missing: docs/index.md (RULES.md §2)' }
    )
    foreach ($c in $checks) {
        if (-not (Test-Path -LiteralPath $c.Path -PathType $c.Type)) {
            Write-Err $c.Msg; $fail = 1
        }
    }

    # Files > 1000 lines
    if (Test-Path -LiteralPath 'src' -PathType Container) {
        foreach ($file in (Get-ChildItem -LiteralPath 'src' -Recurse -File -ErrorAction SilentlyContinue)) {
            $n = [System.IO.File]::ReadAllLines($file.FullName).Length
            if ($n -gt 1000) {
                Write-Err "file > 1000 lines: $($file.FullName) ($n) — split required (RULES.md §4 step 1)"
                $fail = 1
            }
        }
    }

    if ($fail -eq 0) { Write-Ok 'all checks passed' } else { Write-Err 'compliance check failed' }
    exit $fail
}

function Show-Help {
    Write-Host @'

edi.ps1 — EDI scaffolder + sync tool
Usage:
  edi.ps1 init <name> <language>       Scaffold a new repo from this kit
  edi.ps1 update                       Re-sync Tier-1 (Law) files
  edi.ps1 comply                       Check current repo against the rules
  edi.ps1 help                         Show this help

Languages: python | go | typescript | javascript | bash | cpp | rust | latex

Tier system (RULES.md §10):
  Tier 1 — Law      : force-sync from kit, local edits lost on `update`
  Tier 2 — Scaffold : written at init only, never overwritten
  Tier 3 — Merge    : added if missing, kept if present
  Tier 4 — Local    : never touched

Flags: T = template-substitute ({{TOOL_NAME}}, {{LANGUAGE}})
       R = read-only after sync
       X = executable after sync (Unix only)
'@
}

# ─── Main ─────────────────────────────────────────────────────────────

switch ($Command) {
    'init'   { Invoke-Init -Name $Arg1 -Lang $Arg2 }
    'update' { Invoke-Update }
    'comply' { Invoke-Comply }
    'help'   { Show-Help }
    '-h'     { Show-Help }
    '--help' { Show-Help }
    default  { Write-Err "unknown command: $Command"; Show-Help; exit 1 }
}

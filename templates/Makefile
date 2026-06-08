# ═══════════════════════════════════════════════════════════════════════
# {{TOOL_NAME}} — Makefile
# ═══════════════════════════════════════════════════════════════════════
# Universal targets. Override test/nonreg/integration with your actual
# test runner when development begins.
# ═══════════════════════════════════════════════════════════════════════

.PHONY: build test nonreg integration lint review snapshot clean

# ─── Build ────────────────────────────────────────────────────────────

build:
	@echo "[kit] Override this target: install deps / compile"

# ─── Testing (override with actual runner) ────────────────────────────

test:
	@echo "[kit] Override this target: make test should run tests/units/"
	@exit 1

nonreg:
	@echo "[kit] Override this target: make nonreg should run tests/nonreg/"
	@exit 1

integration:
	@echo "[kit] Override this target: make integration should run tests/integration/"
	@exit 1

lint:
	@echo "[kit] Override this target: language-specific lint"

# ─── Code Quality Review (RULES.md §4) ────────────────────────────────

review:
	@echo "═══ Code Quality Review ═══"
	@echo "0. DEPS      — Run /deps_audit (CVEs + licenses) (BLOCKING)"
	@echo "1. SPLIT     — Break files > 1000 lines into submodules"
	@echo "2. DEDUP     — Eliminate code duplication (>10 lines)"
	@echo "3. LIBRARIES — Extract shared code into libraries"
	@echo "4. NAMING    — Enforce naming conventions (see RULES.md §1)"
	@echo "5. FILES     — Enforce file naming and structure"
	@echo "6. SECURITY  — Check for forbidden patterns (BLOCKING)"
	@echo "7. REFACTOR  — Structural improvements, dead code removal"
	@echo "8. OPTIMIZE  — Performance pass (measurably slow code only)"
	@echo ""
	@echo "Run each step manually. Every fix follows the TDD procedure."

# ─── Snapshot (RULES.md §9) ───────────────────────────────────────────

snapshot:
	@if [ -z "$(CODENAME)" ]; then echo "Usage: make snapshot CODENAME=orion"; exit 1; fi
	@SNAP_DIR="snapshots/$(CODENAME)-$$(date +%Y-%m-%d)"; \
	mkdir -p "$$SNAP_DIR"; \
	echo "# Snapshot: $(CODENAME)" > "$$SNAP_DIR/snapshot.md"; \
	echo "" >> "$$SNAP_DIR/snapshot.md"; \
	echo "- **Date**: $$(date +%Y-%m-%d)" >> "$$SNAP_DIR/snapshot.md"; \
	echo "- **Codename**: $(CODENAME)" >> "$$SNAP_DIR/snapshot.md"; \
	echo "" >> "$$SNAP_DIR/snapshot.md"; \
	echo "## What was frozen" >> "$$SNAP_DIR/snapshot.md"; \
	echo "" >> "$$SNAP_DIR/snapshot.md"; \
	echo "Describe the snapshot state here." >> "$$SNAP_DIR/snapshot.md"; \
	echo ""; \
	echo "Frozen to $$SNAP_DIR/"

# ─── Clean ────────────────────────────────────────────────────────────

clean:
	@echo "[kit] Override this target with project-specific cleanup"

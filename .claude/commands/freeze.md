---
disable-model-invocation: true
---
# Snapshot (Freeze)

Capture an immutable checkpoint of one or more files — UI layouts, schemas, configs, specs, anything that must not drift.

Steps:
1. Pick the next available codename from `configs/codenames.yml`
2. Create `snapshots/<codename>-YYYY-MM-DD/`
3. Copy every file being frozen into the subfolder
4. Create `snapshots/<codename>-YYYY-MM-DD/snapshot.md` (use `templates/snapshot.md` if present, else write it inline)
5. Mark the codename as assigned in `configs/codenames.yml`
6. Commit: `chore(snapshot): freeze <codename>`

Rules:
- Immutable — never edit files inside a snapshot folder.
- To update: create a NEW snapshot with a new codename — do not modify the old one.
- Snapshot folders are never deleted.
- Every snapshot requires a `snapshot.md` describing what was frozen and why.

# Checklist — Podpal Sync

## Current Phase: Phase 1 — MVP (ready to build)

### In Progress
- [ ] Task 1: Xcode project scaffold

### Done
- [x] Feature list defined
- [x] Architecture decided (Swift/SwiftUI menu bar app, Rockbox-only)
- [x] Per-iPod profile design decided (serial number based)
- [x] CLAUDE.md created
- [x] Implementation plan written (`docs/plans/2026-03-05-podpal-sync-mvp.md`)

---

## Phases

### Phase 1: MVP
- [ ] Project scaffold (Xcode project, SwiftUI menu bar app)
- [ ] iPod mount detection (DiskArbitration)
- [ ] Serial number reading + iPod identification
- [ ] Profile model + persistence (JSON/UserDefaults)
- [ ] Profile editor UI (add iPod, add sync rules)
- [ ] Sync engine (delta sync: copy new/changed, delete removed)
- [ ] Sync progress UI
- [ ] Album art extractor (embedded → cover.jpg)
- [ ] Post-sync reminder (trigger Rockbox database update)
- [ ] .DS_Store / junk file exclusion

### Phase 2: Polish
- [ ] Sequoia 15.4.1+ mount detection + workaround guide
- [ ] iFlash corruption warning (remind to use disk mode)
- [ ] Multiple iPod support tested with real hardware
- [ ] Format conversion (FLAC → ALAC for older models)
- [ ] Link to Podpal web app for boot logo patching
- [ ] App icon + menu bar icon

### Phase 3: Distribution
- [ ] GitHub repo created
- [ ] Code signing / notarization
- [ ] DMG build for direct download
- [ ] README with install instructions
- [ ] Consider Mac App Store submission

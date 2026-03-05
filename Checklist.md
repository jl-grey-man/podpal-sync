# Checklist — Podpal Sync

## Current Phase: Phase 2 — Polish

### Next Up (tomorrow)
- [ ] Install Xcode from Mac App Store (~10 GB)
- [ ] Build and test in Xcode (`open PodpalSync.xcodeproj`, then Cmd+U to run tests)
- [ ] Test on real iPod hardware

### Done — Phase 1
- [x] Feature list defined
- [x] Architecture decided (Swift/SwiftUI menu bar app, Rockbox-only)
- [x] Per-iPod profile design decided (serial number based)
- [x] CLAUDE.md created
- [x] Implementation plan written (`docs/plans/2026-03-05-podpal-sync-mvp.md`)
- [x] Xcode project scaffold (project.yml + xcodegen)
- [x] iPod mount detection (NSWorkspace notifications)
- [x] Serial number reading from `iPod_Control/Device/SysInfo`
- [x] Profile model + persistence (ProfileStore → UserDefaults/JSON)
- [x] Profile editor UI (ProfileListView, ProfileEditView, SyncRuleRowView)
- [x] Sync engine (SyncEngine actor — delta sync: copy new/changed, delete removed)
- [x] Sync progress UI (SyncStatusView)
- [x] Album art extractor (ArtExtractor actor — embedded art → cover.jpg)
- [x] .DS_Store / junk file exclusion (in SyncEngine.fileMap)
- [x] Unit tests (ProfileStore, SyncEngine, IPodDetector, ArtExtractor)
- [x] GitHub repo created (https://github.com/jl-grey-man/podpal-sync)

---

## Phases

### Phase 2: Polish
- [ ] Sequoia 15.4.1+ mount detection + workaround guide
- [ ] iFlash corruption warning (remind to use disk mode)
- [ ] Post-sync reminder (user prompt to trigger Rockbox database update)
- [ ] Multiple iPod support tested with real hardware
- [ ] App icon + menu bar icon
- [ ] Link to Podpal web app for boot logo patching

### Phase 3: Advanced
- [ ] Format conversion (FLAC → ALAC for older models)

### Phase 4: Distribution
- [ ] Code signing / notarization
- [ ] DMG build for direct download
- [ ] README with install instructions
- [ ] Consider Mac App Store submission

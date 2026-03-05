# Rules

## Never break what works
- Run the FULL test suite before AND after every change — not just the tests you think are related
- If any test fails after your change, revert and fix before proceeding
- Never modify code you weren't asked to touch
- Never refactor, "improve", or clean up adjacent code while working on something else
- Check that the application still starts/builds after every change

## Atomic changes only
- One logical change per commit
- Every commit must leave the project in a working state (tests green, app builds)
- If a change touches multiple files, they all go in one commit — but the change itself stays minimal
- No "while I'm here" fixes — make a separate commit or note it for later

## Documentation is not optional
- If you change behavior, update the docs in the SAME commit (not "later")
- This file (CLAUDE.md) is the source of truth — if code contradicts it, the code is wrong
- New pattern or convention? Document it here BEFORE using it
- Removing a feature? Remove its documentation in the same commit
- Added a new dependency? Update CLAUDE.md
- Added or changed commands/scripts? Update CLAUDE.md
- Changed directory structure or deployed files? Update CLAUDE.md
- New environment variables required? Update CLAUDE.md
- Discovered a fragile area? Add it to the Fragile section

## Don't guess, ask
- Ambiguous requirements → ask before implementing
- Unsure if a change will break something → say so
- Unfamiliar with a pattern in the codebase → read it first, don't assume
- Never assume "this is probably fine"

## Test discipline
- New code = new tests (same commit)
- Changed behavior = updated tests (same commit)
- Tests must verify behavior, not just cover lines
- If the project has no tests yet, add them for any new code you write

## Failure is an option
- If you don't know how to fix something, SAY SO — don't fake a solution
- "I don't know" is always better than a wrong fix that hides the real problem
- Never paper over errors with try/catch, silent fallbacks, or suppressed warnings
- If a fix feels like guesswork, stop and explain what you've tried and where you're stuck

## Diagnose before you fix
- Never start changing code until you understand WHY it's broken
- Read the error, trace the code path, check the logs — then fix
- Don't throw code at the problem hoping something sticks
- If your first fix didn't work, stop and re-analyze — don't try a second guess
- "I changed 5 things and now it works" means you don't know what fixed it — revert and do it properly

## No shortcuts, no quickfixes
- Every fix must be a proper fix — no hacks, workarounds, or "temporary" solutions
- If doing it properly takes longer, that's fine — stability beats speed
- Never disable a check, skip validation, or comment out code to make something work
- If the proper fix is too complex for the current scope, say so instead of hacking around it

## Respect the Fragile section
- Before changing ANY code, check the Fragile section below for warnings about that area
- If your change touches a fragile area, take extra care and test more thoroughly
- If you discover a new fragile area (tight coupling, brittle integration, non-obvious dependency), add it to the Fragile section

## Task tracking belongs in Checklist.md
- Never put todos, progress tracking, or phase status in CLAUDE.md
- Use Checklist.md for all task tracking — it's the living progress doc
- Check off items as you complete them
- When starting a new phase or big task, update the checklist first

---

# Podpal Sync — Rockbox iPod Sync for macOS

Native macOS menu bar app that syncs music to Rockbox iPods. Detects connected iPods by serial number, applies per-iPod sync rules (source folder → destination folder), handles album art extraction, and guides users through the Sequoia 15.4.1+ mounting workaround.

**Companion to:** https://github.com/jl-grey-man/podpal (web-based boot logo patcher)

**Implementation plan:** `docs/plans/2026-03-05-podpal-sync-mvp.md`

## Requirements

- **Xcode** (not installed yet — download from Mac App Store, ~10 GB)
- macOS 13 Ventura or later
- `xcodegen` (`brew install xcodegen`) — regenerate `.xcodeproj` after editing `project.yml`

## Commands

```bash
open PodpalSync.xcodeproj   # open in Xcode
cmd+B                       # build
cmd+U                       # run tests
cmd+R                       # run app
xcodegen generate           # regenerate xcodeproj after changing project.yml
```

## Architecture

```
PodpalSync/
  App/
    PodpalSyncApp.swift      # @main, menu bar setup
    AppDelegate.swift        # NSStatusItem, popover
  Features/
    iPodDetection/
      iPodMonitor.swift      # DiskArbitration / NSWorkspace mount notifications
      iPodIdentifier.swift   # read serial number from mounted volume
    Profiles/
      Profile.swift          # iPod profile model (name, serial, sync rules)
      ProfileStore.swift     # persist profiles to UserDefaults/JSON
    Sync/
      SyncEngine.swift       # delta sync: compare, copy, delete
      AlbumArtExtractor.swift # extract embedded art → cover.jpg
    Sequoia/
      MountHelper.swift      # detect unmounted iPod, guide/attempt fix
    UI/
      MenuBarView.swift      # SwiftUI popover content
      ProfileEditorView.swift # add/edit iPod profiles and sync rules
      SyncProgressView.swift  # live sync progress
  Tests/
    SyncEngineTests.swift
    AlbumArtExtractorTests.swift
    ProfileStoreTests.swift
    iPodIdentifierTests.swift
```

## Tech Stack

- **Swift 5.9+ / SwiftUI** — UI and app logic
- **MenuBarExtra** (macOS 13+) — menu bar presence
- **DiskArbitration** — low-level disk mount/unmount callbacks
- **NSWorkspace** — volume mount notifications (fallback)
- **AVFoundation / ImageIO** — read embedded album art from audio files
- **FileManager** — file copy, delta comparison
- **UserDefaults + JSONEncoder** — profile persistence
- **XCTest** — unit tests

## Minimum Target

macOS 13 Ventura (MenuBarExtra requires 13+)

## Key Design Decisions

- **Rockbox only** — no iTunesDB support. Rockbox reads files directly from folders.
- **Per-iPod profiles by serial number** — plug in any known iPod, correct rules apply automatically
- **Delta sync** — compare modification dates + file size; only copy changed files
- **Album art** — Rockbox ignores embedded art; app extracts to `cover.jpg` per album folder
- **No auto-sync on first connect** — always confirm before first sync on a new iPod

## Fragile Areas

- **DiskArbitration callbacks** — run on a background thread; all UI updates must dispatch to main
- **Serial number reading** — varies by iPod model and macOS version; test on real hardware
- **Sequoia 15.4.1+ mounting** — Apple broke standard mounting; `mount_hfs` workaround may require root or change in future OS updates
- **Album art extraction** — AVFoundation is async; must handle files without art gracefully without crashing

## Gotchas

- Rockbox database does NOT update automatically after file sync — user must go to Settings → Database → Update Now, or it happens on next reboot. Always remind the user after sync.
- `.DS_Store`, `Thumbs.db`, and `desktop.ini` must be excluded from sync — never copy these to the iPod
- iFlash-modded iPods: always transfer via Apple OS (disk mode), not Rockbox USB mode, to avoid filesystem corruption. App should warn about this.
- `cover.jpg` must be a baseline JPEG (not progressive) — Rockbox does not support progressive JPEGs for album art

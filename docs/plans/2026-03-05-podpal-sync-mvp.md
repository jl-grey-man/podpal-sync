# Podpal Sync MVP — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Native macOS menu bar app that syncs music from configured local folders to Rockbox iPods, with per-iPod profiles keyed by serial number, delta sync, and automatic album art extraction.

**Architecture:** MenuBarExtra (macOS 13+) with a SwiftUI popover. iPod detection via NSWorkspace mount notifications. Profiles stored as JSON in UserDefaults. Sync runs as a background async Task. All UI updates on main actor.

**Tech Stack:** Swift 5.9+, SwiftUI, macOS 13+, AVFoundation (album art), FileManager, NSWorkspace, XCTest. No third-party dependencies.

---

## Project Structure

```
PodpalSync/
├── PodpalSync.xcodeproj
├── PodpalSync/
│   ├── PodpalSyncApp.swift
│   ├── Models/
│   │   ├── SyncRule.swift
│   │   ├── IPodProfile.swift
│   │   └── SyncResult.swift
│   ├── Services/
│   │   ├── IPodDetector.swift
│   │   ├── SyncEngine.swift
│   │   ├── ArtExtractor.swift
│   │   └── SyncCoordinator.swift
│   ├── Storage/
│   │   └── ProfileStore.swift
│   └── Views/
│       ├── MenuBarView.swift
│       ├── SyncStatusView.swift
│       ├── ProfileListView.swift
│       ├── ProfileEditView.swift
│       └── SyncRuleRowView.swift
├── PodpalSyncTests/
│   ├── SyncEngineTests.swift
│   ├── ArtExtractorTests.swift
│   └── ProfileStoreTests.swift
```

---

## Task 1: Xcode project scaffold

**Files:**
- Create: `PodpalSync/PodpalSyncApp.swift`
- Create: `PodpalSync/Views/MenuBarView.swift`

**Step 1: Create Xcode project**

- Open Xcode → New Project → macOS → App
- Product Name: `PodpalSync`
- Interface: SwiftUI, Language: Swift
- Minimum deployment: **macOS 13.0**
- Uncheck "Create Git repository"
- Save to `~/Documents/-ai_projects-/podpal-sync/`

**Step 2: Configure as menu bar app — no Dock icon**

In `Info.plist`, add:
```xml
<key>LSUIElement</key>
<true/>
```

**Step 3: Replace PodpalSyncApp.swift**

```swift
import SwiftUI

@main
struct PodpalSyncApp: App {
    var body: some Scene {
        MenuBarExtra("Podpal Sync", systemImage: "music.note") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 4: Create placeholder MenuBarView.swift**

```swift
import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Podpal Sync").font(.headline).padding()
            Divider()
            Text("No iPod connected").foregroundStyle(.secondary).padding()
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }.padding()
        }
        .frame(width: 300)
    }
}
```

**Step 5: Build and run**

`Cmd+R` — music note icon appears in menu bar. Click it → popover opens.

**Step 6: Init git**

```bash
cd ~/Documents/-ai_projects-/podpal-sync
git init
echo ".DS_Store\n*.xcuserstate\nxcuserdata/\nDerivedData/" > .gitignore
git add .
git commit -m "feat: scaffold menu bar app"
```

---

## Task 2: Data models

**Files:**
- Create: `PodpalSync/Models/SyncRule.swift`
- Create: `PodpalSync/Models/IPodProfile.swift`
- Create: `PodpalSync/Models/SyncResult.swift`
- Create: `PodpalSyncTests/ProfileStoreTests.swift`

**Step 1: Write failing tests**

```swift
// PodpalSyncTests/ProfileStoreTests.swift
import XCTest
@testable import PodpalSync

final class ModelTests: XCTestCase {
    func test_syncRule_roundtrips_json() throws {
        let rule = SyncRule(id: UUID(), sourcePath: "/Users/test/Music", destinationPath: "/Music")
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(SyncRule.self, from: data)
        XCTAssertEqual(rule.sourcePath, decoded.sourcePath)
        XCTAssertEqual(rule.destinationPath, decoded.destinationPath)
    }

    func test_ipodProfile_roundtrips_json() throws {
        let profile = IPodProfile(id: UUID(), serialNumber: "ABC123", displayName: "Red Classic", syncRules: [])
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(IPodProfile.self, from: data)
        XCTAssertEqual(profile.serialNumber, decoded.serialNumber)
        XCTAssertEqual(profile.displayName, decoded.displayName)
    }
}
```

**Step 2: Run — expect failure (types undefined)**

`Cmd+U`

**Step 3: Implement models**

```swift
// SyncRule.swift
import Foundation

struct SyncRule: Identifiable, Codable, Equatable {
    var id: UUID
    var sourcePath: String      // absolute path on Mac
    var destinationPath: String // relative path on iPod e.g. "/Music/Jazz"
}
```

```swift
// IPodProfile.swift
import Foundation

struct IPodProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var serialNumber: String
    var displayName: String
    var syncRules: [SyncRule]
    var extractAlbumArt: Bool = true
    var lastSyncDate: Date? = nil
}
```

```swift
// SyncResult.swift
import Foundation

struct SyncResult: Equatable {
    let iPodName: String
    let filesAdded: Int
    let filesRemoved: Int
    let filesSkipped: Int
    let artExtracted: Int
    let errors: [String]
    let duration: TimeInterval

    var summary: String { "+\(filesAdded) -\(filesRemoved) =\(filesSkipped) skipped" }
}
```

**Step 4: Run — expect pass**

**Step 5: Commit**

```bash
git add PodpalSync/Models/ PodpalSyncTests/
git commit -m "feat: data models (SyncRule, IPodProfile, SyncResult)"
```

---

## Task 3: Profile storage

**Files:**
- Create: `PodpalSync/Storage/ProfileStore.swift`
- Modify: `PodpalSyncTests/ProfileStoreTests.swift`

**Step 1: Add failing tests**

```swift
// Add to ProfileStoreTests.swift
func test_save_and_load() {
    let store = ProfileStore(suiteName: "test.\(UUID().uuidString)")
    let profile = IPodProfile(id: UUID(), serialNumber: "XYZ789", displayName: "Black Nano", syncRules: [])
    store.save(profile)
    XCTAssertEqual(store.profile(forSerial: "XYZ789")?.displayName, "Black Nano")
}

func test_delete() {
    let store = ProfileStore(suiteName: "test.\(UUID().uuidString)")
    let profile = IPodProfile(id: UUID(), serialNumber: "DEL001", displayName: "Old iPod", syncRules: [])
    store.save(profile)
    store.delete(serialNumber: "DEL001")
    XCTAssertNil(store.profile(forSerial: "DEL001"))
}
```

**Step 2: Run — expect failure**

**Step 3: Implement**

```swift
// ProfileStore.swift
import Foundation

@Observable
final class ProfileStore {
    private let defaults: UserDefaults
    private let key = "ipod_profiles"
    private(set) var profiles: [IPodProfile] = []

    init(suiteName: String = "com.podpal.sync") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.profiles = load()
    }

    func profile(forSerial serial: String) -> IPodProfile? {
        profiles.first { $0.serialNumber == serial }
    }

    func save(_ profile: IPodProfile) {
        if let idx = profiles.firstIndex(where: { $0.serialNumber == profile.serialNumber }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        persist()
    }

    func delete(serialNumber: String) {
        profiles.removeAll { $0.serialNumber == serialNumber }
        persist()
    }

    private func load() -> [IPodProfile] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([IPodProfile].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: key)
    }
}
```

**Step 4: Run — expect pass**

**Step 5: Commit**

```bash
git add PodpalSync/Storage/ PodpalSyncTests/
git commit -m "feat: profile storage with UserDefaults"
```

---

## Task 4: iPod detection

**Files:**
- Create: `PodpalSync/Services/IPodDetector.swift`
- Create: `PodpalSyncTests/IPodDetectorTests.swift`

**Step 1: Write failing tests**

```swift
// IPodDetectorTests.swift
import XCTest
@testable import PodpalSync

final class IPodDetectorTests: XCTestCase {
    func test_isRockboxVolume_recognizes_rockbox_folder() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let rockboxDir = tmp.appendingPathComponent(".rockbox")
        try FileManager.default.createDirectory(at: rockboxDir, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: rockboxDir.appendingPathComponent("rockbox.ipod").path,
            contents: Data()
        )
        XCTAssertTrue(IPodDetector.isRockboxVolume(at: tmp))
        try FileManager.default.removeItem(at: tmp)
    }

    func test_isRockboxVolume_rejects_non_rockbox() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        XCTAssertFalse(IPodDetector.isRockboxVolume(at: tmp))
        try FileManager.default.removeItem(at: tmp)
    }
}
```

**Step 2: Run — expect failure**

**Step 3: Implement**

```swift
// IPodDetector.swift
import Foundation
import AppKit

@Observable
@MainActor
final class IPodDetector {
    private(set) var connectedVolumes: [DetectedIPod] = []

    struct DetectedIPod: Identifiable, Equatable {
        let id = UUID()
        let volumeURL: URL
        let volumeName: String
        let serialNumber: String?
    }

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(volumeMounted(_:)),
            name: NSWorkspace.didMountNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(volumeUnmounted(_:)),
            name: NSWorkspace.didUnmountNotification, object: nil
        )
    }

    @objc private func volumeMounted(_ n: Notification) {
        guard let url = n.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL,
              Self.isRockboxVolume(at: url) else { return }
        let iPod = DetectedIPod(
            volumeURL: url,
            volumeName: url.lastPathComponent,
            serialNumber: Self.readSerial(from: url)
        )
        connectedVolumes.append(iPod)
    }

    @objc private func volumeUnmounted(_ n: Notification) {
        guard let url = n.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        connectedVolumes.removeAll { $0.volumeURL == url }
    }

    static func isRockboxVolume(at url: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".rockbox/rockbox.ipod").path
        )
    }

    static func readSerial(from url: URL) -> String? {
        let sysInfo = url.appendingPathComponent("iPod_Control/Device/SysInfo")
        guard let content = try? String(contentsOf: sysInfo, encoding: .utf8) else { return nil }
        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("SerialNumber:") {
                return line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
```

**Step 4: Run — expect pass**

**Step 5: Commit**

```bash
git add PodpalSync/Services/IPodDetector.swift PodpalSyncTests/IPodDetectorTests.swift
git commit -m "feat: iPod detection via NSWorkspace mount notifications"
```

---

## Task 5: Sync engine

**Files:**
- Create: `PodpalSync/Services/SyncEngine.swift`
- Create: `PodpalSyncTests/SyncEngineTests.swift`

**Step 1: Write failing tests**

```swift
// SyncEngineTests.swift
import XCTest
@testable import PodpalSync

final class SyncEngineTests: XCTestCase {
    var src: URL!
    var dst: URL!

    override func setUp() {
        let tmp = FileManager.default.temporaryDirectory
        src = tmp.appendingPathComponent("src-\(UUID().uuidString)")
        dst = tmp.appendingPathComponent("dst-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: src, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: src)
        try? FileManager.default.removeItem(at: dst)
    }

    func test_copies_new_file() async throws {
        try Data("audio".utf8).write(to: src.appendingPathComponent("song.mp3"))
        let engine = SyncEngine()
        let result = try await engine.sync(from: src, to: dst)
        XCTAssertEqual(result.filesAdded, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.appendingPathComponent("song.mp3").path))
    }

    func test_skips_unchanged_file() async throws {
        let data = Data("audio".utf8)
        let srcFile = src.appendingPathComponent("song.mp3")
        let dstFile = dst.appendingPathComponent("song.mp3")
        try data.write(to: srcFile)
        try data.write(to: dstFile)
        // Match modification dates so file appears unchanged
        let attrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        try FileManager.default.setAttributes(attrs, ofItemAtPath: dstFile.path)
        let engine = SyncEngine()
        let result = try await engine.sync(from: src, to: dst)
        XCTAssertEqual(result.filesAdded, 0)
        XCTAssertEqual(result.filesSkipped, 1)
    }

    func test_removes_deleted_file() async throws {
        let dstFile = dst.appendingPathComponent("old.mp3")
        try Data("old".utf8).write(to: dstFile)
        let engine = SyncEngine()
        let result = try await engine.sync(from: src, to: dst)
        XCTAssertEqual(result.filesRemoved, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dstFile.path))
    }
}
```

**Step 2: Run — expect failure**

**Step 3: Implement**

```swift
// SyncEngine.swift
import Foundation

actor SyncEngine {
    private let audioExtensions: Set<String> = ["mp3","flac","aac","m4a","ogg","opus","wav","aiff"]
    private let junkFiles: Set<String> = [".ds_store","thumbs.db","desktop.ini"]

    func sync(from source: URL, to destination: URL) async throws -> SyncResult {
        let start = Date()
        var added = 0, removed = 0, skipped = 0
        var errors: [String] = []
        let fm = FileManager.default

        let srcMap = try fileMap(at: source)
        let dstMap = try fileMap(at: destination)

        // Copy new or modified
        for (rel, srcDate) in srcMap {
            let srcURL = source.appendingPathComponent(rel)
            let dstURL = destination.appendingPathComponent(rel)
            if let dstDate = dstMap[rel], dstDate >= srcDate {
                skipped += 1; continue
            }
            do {
                try fm.createDirectory(at: dstURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                if fm.fileExists(atPath: dstURL.path) { try fm.removeItem(at: dstURL) }
                try fm.copyItem(at: srcURL, to: dstURL)
                added += 1
            } catch {
                errors.append("Copy \(rel): \(error.localizedDescription)")
            }
        }

        // Remove stale files
        for rel in dstMap.keys where srcMap[rel] == nil {
            do {
                try fm.removeItem(at: destination.appendingPathComponent(rel))
                removed += 1
            } catch {
                errors.append("Remove \(rel): \(error.localizedDescription)")
            }
        }

        return SyncResult(
            iPodName: destination.lastPathComponent,
            filesAdded: added, filesRemoved: removed, filesSkipped: skipped,
            artExtracted: 0, errors: errors,
            duration: Date().timeIntervalSince(start)
        )
    }

    private func fileMap(at root: URL) throws -> [String: Date] {
        var result: [String: Date] = [:]
        guard let e = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return result }
        for case let url as URL in e {
            guard !url.hasDirectoryPath else { continue }
            let ext = url.pathExtension.lowercased()
            guard audioExtensions.contains(ext) else { continue }
            guard !junkFiles.contains(url.lastPathComponent.lowercased()) else { continue }
            let rel = String(url.path.dropFirst(root.path.count + 1))
            let date = try url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            result[rel] = date
        }
        return result
    }
}
```

**Step 4: Run — expect pass**

**Step 5: Commit**

```bash
git add PodpalSync/Services/SyncEngine.swift PodpalSyncTests/SyncEngineTests.swift
git commit -m "feat: delta sync engine (add/skip/remove by modification date)"
```

---

## Task 6: Album art extractor

**Files:**
- Create: `PodpalSync/Services/ArtExtractor.swift`
- Create: `PodpalSyncTests/ArtExtractorTests.swift`

**Step 1: Write failing tests**

```swift
// ArtExtractorTests.swift
import XCTest
@testable import PodpalSync

final class ArtExtractorTests: XCTestCase {
    func test_skips_directory_with_existing_cover() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try Data("existing".utf8).write(to: tmp.appendingPathComponent("cover.jpg"))
        let extractor = ArtExtractor()
        let count = await extractor.extractArt(inDirectory: tmp)
        XCTAssertEqual(count, 0)
        try FileManager.default.removeItem(at: tmp)
    }
}
```

**Step 2: Run — expect failure**

**Step 3: Implement**

```swift
// ArtExtractor.swift
import Foundation
import AVFoundation

actor ArtExtractor {
    private let audioExtensions: Set<String> = ["mp3","m4a","aac","flac","ogg","opus"]

    /// Walks all subdirectories, extracts embedded art to cover.jpg where missing.
    /// Returns count of files written.
    func extractArt(inDirectory root: URL) async -> Int {
        var count = 0
        let fm = FileManager.default
        guard let e = fm.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return 0 }

        var dirs = Set<URL>()
        for case let url as URL in e {
            if audioExtensions.contains(url.pathExtension.lowercased()) {
                dirs.insert(url.deletingLastPathComponent())
            }
        }

        for dir in dirs {
            let coverURL = dir.appendingPathComponent("cover.jpg")
            guard !fm.fileExists(atPath: coverURL.path) else { continue }
            guard let audioURL = firstAudioFile(in: dir),
                  let artData = extractArtData(from: audioURL) else { continue }
            do {
                try artData.write(to: coverURL)
                count += 1
            } catch { }
        }
        return count
    }

    private func firstAudioFile(in dir: URL) -> URL? {
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return files.first { audioExtensions.contains($0.pathExtension.lowercased()) }
    }

    private func extractArtData(from url: URL) -> Data? {
        let asset = AVAsset(url: url)
        let items = AVMetadataItem.metadataItems(
            from: (try? asset.commonMetadata) ?? [],
            filteredByIdentifier: .commonIdentifierArtwork
        )
        return items.first?.dataValue
    }
}
```

**Step 4: Run — expect pass**

**Step 5: Commit**

```bash
git add PodpalSync/Services/ArtExtractor.swift PodpalSyncTests/ArtExtractorTests.swift
git commit -m "feat: album art extractor (embedded → cover.jpg per album folder)"
```

---

## Task 7: SyncCoordinator

**Files:**
- Create: `PodpalSync/Services/SyncCoordinator.swift`

```swift
// SyncCoordinator.swift
import Foundation

enum SyncState: Equatable {
    case idle
    case syncing(iPodName: String, progress: String)
    case done(SyncResult)
    case failed(String)
}

@Observable
@MainActor
final class SyncCoordinator {
    private(set) var state: SyncState = .idle
    private let store: ProfileStore
    private let engine = SyncEngine()
    private let artExtractor = ArtExtractor()

    init(store: ProfileStore) {
        self.store = store
    }

    func handleDetected(_ iPod: IPodDetector.DetectedIPod) {
        let key = iPod.serialNumber ?? iPod.volumeName
        guard let profile = store.profile(forSerial: key) else { return }
        Task { await runSync(profile: profile, volumeURL: iPod.volumeURL) }
    }

    private func runSync(profile: IPodProfile, volumeURL: URL) async {
        state = .syncing(iPodName: profile.displayName, progress: "Starting…")
        var added = 0, removed = 0, skipped = 0, art = 0
        var errors: [String] = []
        let start = Date()

        for rule in profile.syncRules {
            let src = URL(fileURLWithPath: rule.sourcePath)
            let dst = volumeURL.appendingPathComponent(rule.destinationPath)
            state = .syncing(iPodName: profile.displayName, progress: "Syncing \(src.lastPathComponent)…")
            do {
                let r = try await engine.sync(from: src, to: dst)
                added += r.filesAdded; removed += r.filesRemoved; skipped += r.filesSkipped
                errors += r.errors
                if profile.extractAlbumArt {
                    state = .syncing(iPodName: profile.displayName, progress: "Extracting art…")
                    art += await artExtractor.extractArt(inDirectory: dst)
                }
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        state = .done(SyncResult(
            iPodName: profile.displayName,
            filesAdded: added, filesRemoved: removed, filesSkipped: skipped,
            artExtracted: art, errors: errors,
            duration: Date().timeIntervalSince(start)
        ))
    }
}
```

**Commit:**

```bash
git add PodpalSync/Services/SyncCoordinator.swift
git commit -m "feat: sync coordinator wires detection, engine, and art extraction"
```

---

## Task 8: Complete SwiftUI views

**Step 1: Wire everything in PodpalSyncApp.swift**

```swift
import SwiftUI

@main
struct PodpalSyncApp: App {
    private let store = ProfileStore()
    private let detector = IPodDetector()
    private let coordinator: SyncCoordinator

    init() { coordinator = SyncCoordinator(store: store) }

    var body: some Scene {
        MenuBarExtra("Podpal Sync", systemImage: "music.note") {
            MenuBarView()
                .environment(store)
                .environment(detector)
                .environment(coordinator)
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 2: MenuBarView.swift**

```swift
import SwiftUI

struct MenuBarView: View {
    @Environment(IPodDetector.self) var detector
    @Environment(SyncCoordinator.self) var coordinator
    @State private var showProfiles = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Podpal Sync").font(.headline)
                Spacer()
                Button { showProfiles = true } label: { Image(systemName: "gear") }
                    .buttonStyle(.plain)
            }
            .padding(.horizontal).padding(.vertical, 10)
            Divider()
            SyncStatusView().padding()
            if !detector.connectedVolumes.isEmpty {
                Divider()
                ForEach(detector.connectedVolumes) { ipod in
                    HStack {
                        Image(systemName: "ipodtouch")
                        Text(ipod.volumeName)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                    .padding(.horizontal).padding(.vertical, 6)
                }
            }
            Divider()
            Button("iPod Profiles…") { showProfiles = true }.padding(8)
            Button("Quit") { NSApplication.shared.terminate(nil) }.padding(.bottom, 8)
        }
        .frame(width: 300)
        .sheet(isPresented: $showProfiles) {
            ProfileListView().frame(width: 480, height: 400)
                .environment(store)
        }
        .onChange(of: detector.connectedVolumes) { _, vols in
            vols.forEach { coordinator.handleDetected($0) }
        }
    }
}
```

**Step 3: SyncStatusView.swift**

```swift
import SwiftUI

struct SyncStatusView: View {
    @Environment(SyncCoordinator.self) var coordinator

    var body: some View {
        switch coordinator.state {
        case .idle:
            Label("No sync in progress", systemImage: "moon.zzz").foregroundStyle(.secondary)
        case .syncing(let name, let progress):
            VStack(alignment: .leading, spacing: 4) {
                Label("Syncing \(name)…", systemImage: "arrow.triangle.2.circlepath")
                Text(progress).font(.caption).foregroundStyle(.secondary)
                ProgressView().progressViewStyle(.linear)
            }
        case .done(let r):
            VStack(alignment: .leading, spacing: 4) {
                Label("Done — \(r.iPodName)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Text(r.summary).font(.caption).foregroundStyle(.secondary)
                if r.artExtracted > 0 { Text("\(r.artExtracted) cover.jpg files written").font(.caption).foregroundStyle(.secondary) }
                if !r.errors.isEmpty { Text("\(r.errors.count) error(s)").font(.caption).foregroundStyle(.red) }
                Text("Reminder: Settings → Database → Update Now on your iPod")
                    .font(.caption2).foregroundStyle(.orange).padding(.top, 2)
            }
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
        }
    }
}
```

**Step 4: ProfileListView.swift**

```swift
import SwiftUI

struct ProfileListView: View {
    @Environment(ProfileStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var editing: IPodProfile? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("iPod Profiles").font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                Button("Add") {
                    editing = IPodProfile(id: UUID(), serialNumber: "", displayName: "My iPod", syncRules: [])
                }
            }
            .padding()
            Divider()
            if store.profiles.isEmpty {
                Text("No profiles yet. Click Add to configure an iPod.")
                    .foregroundStyle(.secondary).padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.profiles) { p in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(p.displayName).font(.headline)
                                Text("\(p.syncRules.count) rule(s) · \(p.serialNumber)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") { editing = p }
                            Button("Delete") { store.delete(serialNumber: p.serialNumber) }
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .sheet(item: $editing) { p in
            ProfileEditView(profile: p).frame(width: 480, height: 500)
                .environment(store)
        }
    }
}
```

**Step 5: ProfileEditView.swift + SyncRuleRowView.swift**

```swift
// ProfileEditView.swift
import SwiftUI

struct ProfileEditView: View {
    @Environment(ProfileStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State var profile: IPodProfile

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Profile").font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { store.save(profile); dismiss() }.buttonStyle(.borderedProminent)
            }
            .padding()
            Divider()
            Form {
                Section("iPod") {
                    TextField("Name", text: $profile.displayName)
                    TextField("Serial Number", text: $profile.serialNumber)
                        .font(.system(.body, design: .monospaced))
                    Toggle("Extract album art automatically", isOn: $profile.extractAlbumArt)
                }
                Section("Sync Rules") {
                    ForEach($profile.syncRules) { $rule in
                        SyncRuleRowView(rule: $rule) {
                            profile.syncRules.removeAll { $0.id == rule.id }
                        }
                    }
                    Button("Add Rule") {
                        profile.syncRules.append(SyncRule(id: UUID(), sourcePath: "", destinationPath: "/Music"))
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}

// SyncRuleRowView.swift
struct SyncRuleRowView: View {
    @Binding var rule: SyncRule
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("From:").frame(width: 40, alignment: .trailing)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(rule.sourcePath.isEmpty ? "Not set" : URL(fileURLWithPath: rule.sourcePath).lastPathComponent)
                        .lineLimit(1)
                    Spacer()
                    Button("Choose…") { pickSource() }.font(.caption)
                }
                HStack {
                    Text("To:").frame(width: 40, alignment: .trailing)
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("/Music", text: $rule.destinationPath)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            Button(action: onDelete) { Image(systemName: "trash").foregroundStyle(.red) }
                .buttonStyle(.plain)
        }
    }

    private func pickSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { rule.sourcePath = url.path }
    }
}
```

**Step 6: Build and run — full manual test**

- Menu bar icon visible
- Click → popover opens
- Add a profile → rules editor works, folder picker works
- Save → profile in list

**Step 7: Commit**

```bash
git add PodpalSync/Views/ PodpalSync/PodpalSyncApp.swift
git commit -m "feat: complete SwiftUI UI — menu bar, status, profiles, sync rules"
```

---

## Task 9: Push to GitHub

```bash
cd ~/Documents/-ai_projects-/podpal-sync
gh repo create podpal-sync --public \
  --description "macOS menu bar app for syncing music to Rockbox iPods" \
  --source=. --remote=origin
git push -u origin main
```

---

## Verification Checklist

- [ ] `Cmd+U` — all tests pass
- [ ] `Cmd+R` — menu bar icon visible, no Dock icon
- [ ] Add profile → save → relaunch → profile persists
- [ ] Connect Rockbox iPod → appears in popover
- [ ] Sync runs automatically for known iPod
- [ ] New/changed files copied, unchanged files skipped, deleted files removed
- [ ] `cover.jpg` written into album folders missing art
- [ ] "Settings → Database → Update Now" reminder shown after sync
- [ ] Unknown iPod connected → no sync (no crash)

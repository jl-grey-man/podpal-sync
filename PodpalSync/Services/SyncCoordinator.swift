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
        guard let profile = store.profile(forSerial: key) else {
            // Unknown iPod — don't auto-sync, user needs to configure first
            return
        }
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
                let result = try await engine.sync(from: src, to: dst)
                added += result.filesAdded
                removed += result.filesRemoved
                skipped += result.filesSkipped
                errors += result.errors

                if profile.extractAlbumArt {
                    state = .syncing(iPodName: profile.displayName, progress: "Extracting album art…")
                    art += await artExtractor.extractArt(inDirectory: dst)
                }
            } catch {
                errors.append("Rule '\(rule.sourcePath)': \(error.localizedDescription)")
            }
        }

        state = .done(SyncResult(
            iPodName: profile.displayName,
            filesAdded: added,
            filesRemoved: removed,
            filesSkipped: skipped,
            artExtracted: art,
            errors: errors,
            duration: Date().timeIntervalSince(start)
        ))
    }
}

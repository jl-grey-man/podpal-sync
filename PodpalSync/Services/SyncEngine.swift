import Foundation

actor SyncEngine {
    private let audioExtensions: Set<String> = [
        "mp3", "flac", "aac", "m4a", "ogg", "opus", "wav", "aiff", "alac"
    ]
    private let junkFiles: Set<String> = [
        ".ds_store", "thumbs.db", "desktop.ini", ".spotlightv100"
    ]

    func sync(from source: URL, to destination: URL) async throws -> SyncResult {
        let start = Date()
        var added = 0, removed = 0, skipped = 0
        var errors: [String] = []
        let fm = FileManager.default

        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        let srcMap = try fileMap(at: source)
        let dstMap = try fileMap(at: destination)

        // Copy new or modified files
        for (rel, srcDate) in srcMap {
            let srcURL = source.appendingPathComponent(rel)
            let dstURL = destination.appendingPathComponent(rel)

            if let dstDate = dstMap[rel], dstDate >= srcDate {
                skipped += 1
                continue
            }

            do {
                try fm.createDirectory(
                    at: dstURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                if fm.fileExists(atPath: dstURL.path) {
                    try fm.removeItem(at: dstURL)
                }
                try fm.copyItem(at: srcURL, to: dstURL)
                added += 1
            } catch {
                errors.append("Copy \(rel): \(error.localizedDescription)")
            }
        }

        // Remove files no longer in source
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
            filesAdded: added,
            filesRemoved: removed,
            filesSkipped: skipped,
            artExtracted: 0,
            errors: errors,
            duration: Date().timeIntervalSince(start)
        )
    }

    private func fileMap(at root: URL) throws -> [String: Date] {
        var result: [String: Date] = [:]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return result }

        for case let url as URL in enumerator {
            guard !url.hasDirectoryPath else { continue }
            let ext = url.pathExtension.lowercased()
            guard audioExtensions.contains(ext) else { continue }
            guard !junkFiles.contains(url.lastPathComponent.lowercased()) else { continue }
            let rel = String(url.path.dropFirst(root.path.count + 1))
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            result[rel] = date
        }
        return result
    }
}

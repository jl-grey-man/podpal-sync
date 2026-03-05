import Foundation
import AVFoundation

actor ArtExtractor {
    private let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "flac", "ogg", "opus"]

    /// Walks all subdirectories of root, writes cover.jpg from embedded art
    /// where no cover.jpg already exists. Returns count of files written.
    func extractArt(inDirectory root: URL) async -> Int {
        var count = 0
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        // Collect unique directories that contain audio files
        var dirs = Set<URL>()
        for case let url as URL in enumerator {
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
            } catch {
                // Non-fatal — skip this directory
            }
        }

        return count
    }

    private func firstAudioFile(in dir: URL) -> URL? {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )) ?? []
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

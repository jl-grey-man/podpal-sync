import XCTest
import Foundation
@testable import PodpalSync

final class ArtExtractorTests: XCTestCase {
    let extractor = ArtExtractor()

    func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testReturnsZeroForEmptyDirectory() async throws {
        let dir = try makeTempDir()
        let count = await extractor.extractArt(inDirectory: dir)
        XCTAssertEqual(count, 0)
    }

    func testSkipsDirectoryWithExistingCoverJpg() async throws {
        let dir = try makeTempDir()
        try "audio".write(to: dir.appendingPathComponent("song.mp3"), atomically: true, encoding: .utf8)
        try "jpeg".write(to: dir.appendingPathComponent("cover.jpg"), atomically: true, encoding: .utf8)

        let count = await extractor.extractArt(inDirectory: dir)

        XCTAssertEqual(count, 0)
        // Existing cover.jpg must not be overwritten
        let content = try String(contentsOf: dir.appendingPathComponent("cover.jpg"))
        XCTAssertEqual(content, "jpeg")
    }

    func testIgnoresNonAudioFiles() async throws {
        let dir = try makeTempDir()
        try "text".write(to: dir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)
        try "image".write(to: dir.appendingPathComponent("photo.jpg"), atomically: true, encoding: .utf8)

        let count = await extractor.extractArt(inDirectory: dir)

        XCTAssertEqual(count, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("cover.jpg").path))
    }
}

import XCTest
import Foundation
@testable import PodpalSync

final class SyncEngineTests: XCTestCase {
    let engine = SyncEngine()

    func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func writeFile(_ name: String, in dir: URL, content: String = "audio") throws {
        try content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    func testCopiesNewFiles() async throws {
        let src = try makeTempDir()
        let dst = try makeTempDir()
        try writeFile("song.mp3", in: src)

        let result = try await engine.sync(from: src, to: dst)

        XCTAssertEqual(result.filesAdded, 1)
        XCTAssertEqual(result.filesSkipped, 0)
        XCTAssertEqual(result.filesRemoved, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.appendingPathComponent("song.mp3").path))
    }

    func testSkipsUnchangedFiles() async throws {
        let src = try makeTempDir()
        let dst = try makeTempDir()
        try writeFile("song.mp3", in: src)
        _ = try await engine.sync(from: src, to: dst)
        let result = try await engine.sync(from: src, to: dst)

        XCTAssertEqual(result.filesAdded, 0)
        XCTAssertEqual(result.filesSkipped, 1)
    }

    func testRemovesDeletedFiles() async throws {
        let src = try makeTempDir()
        let dst = try makeTempDir()
        try writeFile("stale.mp3", in: dst)

        let result = try await engine.sync(from: src, to: dst)

        XCTAssertEqual(result.filesRemoved, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dst.appendingPathComponent("stale.mp3").path))
    }

    func testExcludesNonAudioFiles() async throws {
        let src = try makeTempDir()
        let dst = try makeTempDir()
        try writeFile("song.mp3", in: src)
        try writeFile("notes.txt", in: src)
        try writeFile("cover.jpg", in: src)

        let result = try await engine.sync(from: src, to: dst)

        XCTAssertEqual(result.filesAdded, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dst.appendingPathComponent("notes.txt").path))
    }

    func testHandlesSubdirectories() async throws {
        let src = try makeTempDir()
        let dst = try makeTempDir()
        let subdir = src.appendingPathComponent("Album")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        try writeFile("track1.flac", in: subdir)
        try writeFile("track2.flac", in: subdir)

        let result = try await engine.sync(from: src, to: dst)

        XCTAssertEqual(result.filesAdded, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.appendingPathComponent("Album/track1.flac").path))
    }
}

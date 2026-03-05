import XCTest
import Foundation
@testable import PodpalSync

final class IPodDetectorTests: XCTestCase {
    func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testDetectsRockboxVolume() throws {
        let vol = try makeTempDir()
        let rockboxPath = vol.appendingPathComponent(".rockbox")
        try FileManager.default.createDirectory(at: rockboxPath, withIntermediateDirectories: true)
        try "firmware".write(
            to: rockboxPath.appendingPathComponent("rockbox.ipod"),
            atomically: true, encoding: .utf8
        )
        XCTAssertTrue(IPodDetector.isRockboxVolume(at: vol))
    }

    func testRejectsNonRockboxVolume() throws {
        let vol = try makeTempDir()
        XCTAssertFalse(IPodDetector.isRockboxVolume(at: vol))
    }

    func testReadsSerialNumber() throws {
        let vol = try makeTempDir()
        let deviceDir = vol.appendingPathComponent("iPod_Control/Device")
        try FileManager.default.createDirectory(at: deviceDir, withIntermediateDirectories: true)
        let sysInfo = """
        BoardHwSwInterfaceRev: 0x00000002
        ModelNumStr: MA450LL
        SerialNumber: XA123456789A
        FirewireGuid: 0x000A2700xxxxxxxx
        """
        try sysInfo.write(
            to: deviceDir.appendingPathComponent("SysInfo"),
            atomically: true, encoding: .utf8
        )
        XCTAssertEqual(IPodDetector.readSerial(from: vol), "XA123456789A")
    }

    func testReturnsNilWhenSysInfoMissing() throws {
        let vol = try makeTempDir()
        XCTAssertNil(IPodDetector.readSerial(from: vol))
    }

    func testReturnsNilWhenNoSerialLine() throws {
        let vol = try makeTempDir()
        let deviceDir = vol.appendingPathComponent("iPod_Control/Device")
        try FileManager.default.createDirectory(at: deviceDir, withIntermediateDirectories: true)
        try "BoardHwSwInterfaceRev: 0x00000002\nModelNumStr: MA450LL\n".write(
            to: deviceDir.appendingPathComponent("SysInfo"),
            atomically: true, encoding: .utf8
        )
        XCTAssertNil(IPodDetector.readSerial(from: vol))
    }
}

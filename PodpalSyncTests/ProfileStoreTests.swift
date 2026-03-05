import XCTest
import Foundation
@testable import PodpalSync

final class ProfileStoreTests: XCTestCase {
    func makeStore() -> ProfileStore {
        ProfileStore(suiteName: "com.podpal.test.\(UUID().uuidString)")
    }

    func testStartsEmpty() {
        XCTAssertTrue(makeStore().profiles.isEmpty)
    }

    func testSavesNewProfile() {
        let store = makeStore()
        let profile = IPodProfile(
            serialNumber: "SN001", displayName: "My iPod", syncRules: [], extractAlbumArt: true)
        store.save(profile)
        XCTAssertEqual(store.profiles.count, 1)
        XCTAssertEqual(store.profiles.first?.serialNumber, "SN001")
    }

    func testUpdatesExistingProfile() {
        let store = makeStore()
        var profile = IPodProfile(
            serialNumber: "SN001", displayName: "My iPod", syncRules: [], extractAlbumArt: false)
        store.save(profile)
        profile.displayName = "Renamed"
        store.save(profile)
        XCTAssertEqual(store.profiles.count, 1)
        XCTAssertEqual(store.profiles.first?.displayName, "Renamed")
    }

    func testDeletesProfile() {
        let store = makeStore()
        let profile = IPodProfile(
            serialNumber: "SN001", displayName: "My iPod", syncRules: [], extractAlbumArt: false)
        store.save(profile)
        store.delete(serialNumber: "SN001")
        XCTAssertTrue(store.profiles.isEmpty)
    }

    func testLookupBySerial() {
        let store = makeStore()
        let profile = IPodProfile(
            serialNumber: "SN002", displayName: "iPod Nano", syncRules: [], extractAlbumArt: true)
        store.save(profile)
        XCTAssertNotNil(store.profile(forSerial: "SN002"))
        XCTAssertNil(store.profile(forSerial: "WRONG"))
    }

    func testPersistsAcrossInstances() {
        let suite = "com.podpal.test.\(UUID().uuidString)"
        let store1 = ProfileStore(suiteName: suite)
        let profile = IPodProfile(
            serialNumber: "SN003", displayName: "Persisted iPod", syncRules: [], extractAlbumArt: false)
        store1.save(profile)

        let store2 = ProfileStore(suiteName: suite)
        XCTAssertEqual(store2.profiles.count, 1)
        XCTAssertEqual(store2.profile(forSerial: "SN003")?.displayName, "Persisted iPod")
    }
}

import SwiftUI

@main
struct PodpalSyncApp: App {
    @State private var store = ProfileStore()
    @State private var detector = IPodDetector()
    @State private var coordinator: SyncCoordinator

    init() {
        let s = ProfileStore()
        _store = State(initialValue: s)
        _coordinator = State(initialValue: SyncCoordinator(store: s))
    }

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

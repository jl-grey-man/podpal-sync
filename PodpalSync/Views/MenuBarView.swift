import SwiftUI

struct MenuBarView: View {
    @Environment(IPodDetector.self) var detector
    @Environment(SyncCoordinator.self) var coordinator
    @Environment(ProfileStore.self) var store
    @State private var showProfiles = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Podpal Sync").font(.headline)
                Spacer()
                Button { showProfiles = true } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Manage iPod profiles")
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            // Sync status
            SyncStatusView()
                .padding(14)

            // Connected iPods
            if !detector.connectedVolumes.isEmpty {
                Divider()
                ForEach(detector.connectedVolumes) { ipod in
                    HStack(spacing: 8) {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ipod.volumeName).font(.subheadline)
                            Text(store.profile(forSerial: ipod.serialNumber ?? ipod.volumeName) != nil
                                 ? "Profile configured" : "No profile — tap ⚙ to set up")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                }
            }

            Divider()

            // Footer buttons
            Button("iPod Profiles…") { showProfiles = true }
                .padding(.vertical, 6)
            Button("Quit Podpal Sync") { NSApplication.shared.terminate(nil) }
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 320)
        .sheet(isPresented: $showProfiles) {
            ProfileListView()
                .environment(store)
                .frame(width: 500, height: 420)
        }
        .onChange(of: detector.connectedVolumes) { _, volumes in
            for volume in volumes {
                coordinator.handleDetected(volume)
            }
        }
    }
}

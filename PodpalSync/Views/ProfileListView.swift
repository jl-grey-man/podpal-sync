import SwiftUI

struct ProfileListView: View {
    @Environment(ProfileStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var editing: IPodProfile? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("iPod Profiles").font(.headline)
                Spacer()
                Button("Add") {
                    editing = IPodProfile(
                        id: UUID(),
                        serialNumber: "",
                        displayName: "My iPod",
                        syncRules: []
                    )
                }
                .buttonStyle(.borderedProminent)
                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            if store.profiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.questionmark")
                        .font(.system(size: 36)).foregroundStyle(.secondary)
                    Text("No iPods configured")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("Click Add to set up an iPod.\nPlug it in first to get the serial number automatically.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.profiles) { profile in
                        HStack {
                            Image(systemName: "externaldrive.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName).fontWeight(.medium)
                                Text("\(profile.syncRules.count) sync rule(s)  ·  \(profile.serialNumber)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") { editing = profile }
                            Button("Delete") { store.delete(serialNumber: profile.serialNumber) }
                                .foregroundStyle(.red)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .sheet(item: $editing) { profile in
            ProfileEditView(profile: profile)
                .environment(store)
                .frame(width: 500, height: 520)
        }
    }
}

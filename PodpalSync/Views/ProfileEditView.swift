import SwiftUI

struct ProfileEditView: View {
    @Environment(ProfileStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State var profile: IPodProfile

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(profile.displayName.isEmpty ? "New Profile" : profile.displayName)
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { store.save(profile); dismiss() }
                    .buttonStyle(.borderedProminent)
                    .disabled(profile.displayName.isEmpty || profile.serialNumber.isEmpty)
            }
            .padding()

            Divider()

            Form {
                Section("iPod") {
                    LabeledContent("Name") {
                        TextField("e.g. Red Classic", text: $profile.displayName)
                    }
                    LabeledContent("Serial Number") {
                        TextField("Plug in iPod to auto-detect, or enter manually", text: $profile.serialNumber)
                            .font(.system(.body, design: .monospaced))
                    }
                    Toggle("Extract album art automatically", isOn: $profile.extractAlbumArt)
                }

                Section {
                    ForEach($profile.syncRules) { $rule in
                        SyncRuleRowView(rule: $rule) {
                            profile.syncRules.removeAll { $0.id == rule.id }
                        }
                    }
                    Button {
                        profile.syncRules.append(
                            SyncRule(id: UUID(), sourcePath: "", destinationPath: "/Music")
                        )
                    } label: {
                        Label("Add Sync Rule", systemImage: "plus")
                    }
                } header: {
                    Text("Sync Rules")
                } footer: {
                    Text("Each rule copies a folder from your Mac to a folder on the iPod. Only audio files are synced.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
    }
}

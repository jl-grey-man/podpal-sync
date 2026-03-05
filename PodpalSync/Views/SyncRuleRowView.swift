import SwiftUI

struct SyncRuleRowView: View {
    @Binding var rule: SyncRule
    let onDelete: () -> Void

    var sourceLabel: String {
        rule.sourcePath.isEmpty ? "Not set" : URL(fileURLWithPath: rule.sourcePath).lastPathComponent
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("From").frame(width: 36, alignment: .trailing)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(sourceLabel)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button("Choose…") { pickSource() }
                        .font(.caption)
                }
                HStack {
                    Text("To").frame(width: 36, alignment: .trailing)
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("/Music", text: $rule.destinationPath)
                        .font(.system(.caption, design: .monospaced))
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove this sync rule")
        }
        .padding(.vertical, 2)
    }

    private func pickSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        panel.message = "Select the folder on your Mac to sync to this iPod"
        if panel.runModal() == .OK, let url = panel.url {
            rule.sourcePath = url.path
        }
    }
}

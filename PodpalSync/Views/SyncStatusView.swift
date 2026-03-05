import SwiftUI

struct SyncStatusView: View {
    @Environment(SyncCoordinator.self) var coordinator

    var body: some View {
        Group {
            switch coordinator.state {
            case .idle:
                Label("Ready — plug in your iPod", systemImage: "moon.zzz")
                    .foregroundStyle(.secondary)

            case .syncing(let name, let progress):
                VStack(alignment: .leading, spacing: 6) {
                    Label("Syncing \(name)…", systemImage: "arrow.triangle.2.circlepath")
                        .fontWeight(.medium)
                    Text(progress)
                        .font(.caption).foregroundStyle(.secondary)
                    ProgressView()
                        .progressViewStyle(.linear)
                }

            case .done(let result):
                VStack(alignment: .leading, spacing: 4) {
                    Label("Done — \(result.iPodName)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).fontWeight(.medium)
                    Text(result.summary)
                        .font(.caption).foregroundStyle(.secondary)
                    if result.artExtracted > 0 {
                        Text("\(result.artExtracted) cover.jpg file(s) extracted")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !result.errors.isEmpty {
                        Text("\(result.errors.count) error(s) — check logs")
                            .font(.caption).foregroundStyle(.red)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        Text("On your iPod: Settings → Database → Update Now")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    .padding(.top, 2)
                }

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

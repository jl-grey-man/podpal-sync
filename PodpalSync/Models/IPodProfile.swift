import Foundation

struct IPodProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var serialNumber: String     // keyed by serial; falls back to volume name
    var displayName: String
    var syncRules: [SyncRule]
    var extractAlbumArt: Bool = true
    var lastSyncDate: Date? = nil
}

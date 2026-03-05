import Foundation

struct SyncRule: Identifiable, Codable, Equatable {
    var id: UUID
    var sourcePath: String       // absolute path on Mac
    var destinationPath: String  // relative path on iPod, e.g. "/Music/Jazz"
}

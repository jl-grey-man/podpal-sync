import Foundation

struct SyncResult: Equatable {
    let iPodName: String
    let filesAdded: Int
    let filesRemoved: Int
    let filesSkipped: Int
    let artExtracted: Int
    let errors: [String]
    let duration: TimeInterval

    var summary: String {
        "+\(filesAdded) added  −\(filesRemoved) removed  \(filesSkipped) skipped"
    }
}

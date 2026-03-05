import Foundation
import AppKit

@Observable
@MainActor
final class IPodDetector {
    private(set) var connectedVolumes: [DetectedIPod] = []

    struct DetectedIPod: Identifiable, Equatable {
        let id = UUID()
        let volumeURL: URL
        let volumeName: String
        let serialNumber: String?
    }

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(volumeMounted(_:)),
            name: NSWorkspace.didMountNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(volumeUnmounted(_:)),
            name: NSWorkspace.didUnmountNotification, object: nil
        )
    }

    @objc private func volumeMounted(_ notification: Notification) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL,
              Self.isRockboxVolume(at: url) else { return }
        let iPod = DetectedIPod(
            volumeURL: url,
            volumeName: url.lastPathComponent,
            serialNumber: Self.readSerial(from: url)
        )
        connectedVolumes.append(iPod)
    }

    @objc private func volumeUnmounted(_ notification: Notification) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        connectedVolumes.removeAll { $0.volumeURL == url }
    }

    /// A volume is a Rockbox iPod if it has .rockbox/rockbox.ipod
    static func isRockboxVolume(at url: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".rockbox/rockbox.ipod").path
        )
    }

    /// Read serial from iPod_Control/Device/SysInfo (left by Apple firmware)
    static func readSerial(from url: URL) -> String? {
        let sysInfo = url.appendingPathComponent("iPod_Control/Device/SysInfo")
        guard let content = try? String(contentsOf: sysInfo, encoding: .utf8) else { return nil }
        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("SerialNumber:") {
                return line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}

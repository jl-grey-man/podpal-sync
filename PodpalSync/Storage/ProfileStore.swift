import Foundation

@Observable
final class ProfileStore {
    private let defaults: UserDefaults
    private let key = "ipod_profiles"
    private(set) var profiles: [IPodProfile] = []

    init(suiteName: String = "com.podpal.sync") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.profiles = load()
    }

    func profile(forSerial serial: String) -> IPodProfile? {
        profiles.first { $0.serialNumber == serial }
    }

    func save(_ profile: IPodProfile) {
        if let idx = profiles.firstIndex(where: { $0.serialNumber == profile.serialNumber }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        persist()
    }

    func delete(serialNumber: String) {
        profiles.removeAll { $0.serialNumber == serialNumber }
        persist()
    }

    private func load() -> [IPodProfile] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([IPodProfile].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: key)
    }
}

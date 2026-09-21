import Foundation
import Observation

@Observable
class AppSettings {

    var parkingZones: [String] {
        didSet { UserDefaults.standard.set(parkingZones, forKey: "parkingZones") }
    }

    init() {
        // No default zones – each account manages their own
        parkingZones = UserDefaults.standard.stringArray(forKey: "parkingZones") ?? []
    }

    func addZone(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !parkingZones.contains(trimmed) else { return }
        parkingZones.append(trimmed)
    }

    func removeZone(_ name: String) {
        parkingZones.removeAll { $0 == name }
    }

    // MARK: - Cloud sync

    func applyCloudSettings(_ cloud: CloudSyncManager.SyncedSettings,
                            lm: LocalizationManager) {
        parkingZones = cloud.parkingZones
        lm.language = LocalizationManager.Language(rawValue: cloud.language) ?? .english
    }

    func toCloudSettings(lm: LocalizationManager) -> CloudSyncManager.SyncedSettings {
        CloudSyncManager.SyncedSettings(parkingZones: parkingZones,
                                        language: lm.language.rawValue)
    }
}

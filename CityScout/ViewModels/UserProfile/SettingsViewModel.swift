import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    
    // The darkModeEnabled property has been removed to allow the app to follow the system setting.

    private let notificationsEnabledKey = "notificationsEnabledKey"

    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }
    
    func saveNotificationSetting(isEnabled: Bool) {
        notificationsEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: notificationsEnabledKey)
        
        if isEnabled {
            print("Settings: Registering for push notifications...")
        } else {
            print("Settings: Unregistering from push notifications...")
        }
    }
}

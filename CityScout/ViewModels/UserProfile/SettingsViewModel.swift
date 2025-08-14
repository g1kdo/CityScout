import Foundation
import UserNotifications
import StoreKit
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = false
    
    private let notificationsEnabledKey = "notificationsEnabled"
    
    init() {
        loadNotificationSetting()
    }

    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = success
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadNotificationSetting() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    func saveNotificationSetting(isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: notificationsEnabledKey)
        if !isEnabled {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    // MARK: - Rate & Share
    
    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func shareApp() {
        let appUrl = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!
        let activityViewController = UIActivityViewController(activityItems: ["Check out this cool app!", appUrl], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
}

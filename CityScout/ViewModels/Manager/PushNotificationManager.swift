//
//  PushNotificationManager.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import UIKit

// This manager is responsible for handling all push notification logic
class PushNotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    static let shared = PushNotificationManager()
    
    // A callback property to notify the app when a new token is available
    var onTokenRefresh: ((String) -> Void)?
    
    override private init() {
        super.init()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Call this method from your AppDelegate or App entry point
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
            if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
            }
            
            guard granted else { return }
            self.getNotificationSettings()
        }
        
        // Retrieve the current FCM token immediately
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            guard let token = token else {
                print("FCM token is nil.")
                return
            }
            print("Current FCM token: \(token)")
            self.onTokenRefresh?(token)
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - MessagingDelegate
    
    // This is called when a new FCM token is generated or refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "N/A")")
        guard let token = fcmToken else { return }
        self.onTokenRefresh?(token)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // This method is called when a push notification is received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received push notification in foreground: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound])
    }
    
    // This method is called when the user taps on a push notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Tapped on push notification: \(response.notification.request.content.userInfo)")
        
        // You can use the userInfo to navigate to the correct chat or view.
        // For example:
        // if let chatId = response.notification.request.content.userInfo["chatId"] as? String {
        //     // Navigate to ChatView with chatId
        // }
        
        completionHandler()
    }
}


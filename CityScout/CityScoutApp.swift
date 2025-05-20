//
//  CityScoutApp.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import Firebase
import FacebookCore // For ApplicationDelegate
import FBSDKCoreKit // Generally good to import both for completeness if you're using both Core and Login components

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        print("Firebase configured")

        // Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        print("Facebook SDK initialized")

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Ensure Facebook SDK handles the URL callback for login
        let handledByFacebook = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        // If you have other custom URL schemes, you would add their handling here.
        // For example, if you deep link, you might return true if Facebook handled it OR your app handled it.
        // For Facebook login, it's typically enough to just return what Facebook's delegate returns.
        return handledByFacebook
    }
}

@main
struct CityScoutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // The init() block in @main App struct is generally not needed for
    // global configurations like Firebase/Facebook when using @UIApplicationDelegateAdaptor.
    // The AppDelegate's didFinishLaunchingWithOptions is the correct place.
    // If you had specific SwiftUI environment objects you wanted to set up here, you could.
    init() {
        // The AppDelegate will handle FirebaseApp.configure()
        // and ApplicationDelegate.shared.application(...)
        // So, no need to duplicate here unless you have a specific reason
        // for previews that doesn't go through AppDelegate.
        // For most cases, removing this `init` is fine if AppDelegate is the source of truth.
        // If you do keep it, ensure it doesn't try to configure Firebase multiple times.
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}

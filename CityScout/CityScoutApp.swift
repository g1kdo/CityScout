//
//  CityScoutApp.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import Firebase
import FacebookCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Only configure Firebase and Facebook if not running in a preview
        #if !DEBUG
        FirebaseApp.configure()
        print("Firebase configured")

        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        print("Facebook SDK initialized")
        #endif
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        let handled = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        // Add other URL handling, if any
        return handled
    }
}

@main
struct CityScoutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // You might still want to configure Firebase here for previews
        // if your views don't depend on the full AppDelegate setup
        #if DEBUG
        if FirebaseApp.app() == nil { // Prevent multiple configurations in preview
            FirebaseApp.configure()
            print("Firebase configured for preview")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}

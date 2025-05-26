//
//  CityScoutApp.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import Firebase
import FacebookCore
import FBSDKCoreKit

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
        // Let Facebook SDK handle login callbacks
        let handledByFacebook = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
        return handledByFacebook
    }
}

@main
struct CityScoutApp: App {
    // Retain your existing AppDelegate for Firebase & Facebook init
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Inject your authentication view model here
    @StateObject private var authVM = AuthenticationViewModel()

    var body: some Scene {
        WindowGroup {
            if authVM.signedInUser != nil {
                HomeView().environmentObject(authVM)
            }else{
                WelcomeView()
            }
//            WelcomeView()
//                .environmentObject(authVM)
        }
    }
}

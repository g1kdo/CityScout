//
//  CityScoutApp.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import Firebase

@main
struct CityScoutApp: App {
    init(){
        FirebaseApp.configure()
        print("Firebase configured")
    }
    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}

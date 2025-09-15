//
//  RootView.swift
//  CityScout
//
//  Created by Umuco Auca on 14/08/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var destinationVM = DestinationViewModel()

    var body: some View {
        Group {
            if authVM.isLoadingInitialData {
                WelcomeView()
            } else if authVM.isAuthenticated {
                // User is authenticated, now check if they've set their interests
                if authVM.signedInUser?.hasSetInterests == true {
                    // Wrap the main content in a single NavigationStack
                    NavigationStack {
                        HomeView()
                            .environmentObject(destinationVM)
                    }
                } else {
                    InterestView()
                }
            } else {
                WelcomeView()
            }
        }
    }
}

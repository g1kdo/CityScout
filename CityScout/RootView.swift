//
//  RootView.swift
//  CityScout
//
//  Created by Umuco Auca on 14/08/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var partnerAuthVM: PartnerAuthenticationViewModel
    @StateObject private var destinationVM = DestinationViewModel()

    var body: some View {
        Group {
            // First check if we're still loading (either partner or user)
            if partnerAuthVM.isLoadingInitialData || authVM.isLoadingInitialData {
                WelcomeView()
            }
            // Priority 1: Check if user is authenticated as a PARTNER
            else if partnerAuthVM.isAuthenticated && partnerAuthVM.signedInPartner != nil {
                // Partner is authenticated, show partner view
                NavigationStack {
                    PartnerMessagesView()
                        .environmentObject(authVM) // Provide authVM for ChatView compatibility
                }
            }
            // Priority 2: Check if user is authenticated as a regular USER
            else if authVM.isAuthenticated {
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
            }
            // No one is authenticated, show welcome screen
            else {
                WelcomeView()
            }
        }
    }
}

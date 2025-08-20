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
                // Show a loading indicator while the user's data is being fetched

                WelcomeView()
            } else if authVM.isAuthenticated {
                // User is authenticated, now check if they've set their interests
                if authVM.signedInUser?.hasSetInterests == true {
                    HomeView()
                        .environmentObject(destinationVM)
                } else {
                    // User is authenticated but hasn't set interests, show the interest page
                    InterestView()
                }
            } else {
                // User is not authenticated, show the login/welcome screen
                //                ProgressView()
                //                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

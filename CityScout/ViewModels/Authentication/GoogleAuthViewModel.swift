//
//  GoogleAuthViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@MainActor
class GoogleAuthViewModel: ObservableObject {
    // authenticationState, user, signedInUser, displayName are no longer needed here
    // as AuthenticationViewModel will be the single source of truth for the user state.
    @Published var errorMessage: String = ""

    // No need for authStateHandler in this ViewModel, AuthenticationViewModel handles it.
    // init() and deinit() methods are removed as well.

    func signInWithGoogle() async -> FirebaseAuth.User? { // Changed return type to FirebaseAuth.User?
        errorMessage = "" // Clear previous error

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Client ID not found in Firebase configuration. Make sure GoogleService-Info.plist is correctly set up."
            return nil
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Root view controller not found for Google Sign-In presentation."
            return nil
        }

        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = userAuthentication.user.idToken else {
                errorMessage = "Google ID token missing after sign-in."
                return nil
            }
            let accessToken = userAuthentication.user.accessToken

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: accessToken.tokenString
            )

            let result = try await Auth.auth().signIn(with: credential)
            print("Google Sign-In successful in GoogleAuthViewModel. Returning Firebase User.")
            return result.user // Return the Firebase User for AuthenticationViewModel to process
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            print("Google Sign-In failed: \(error.localizedDescription)")
            return nil
        }
    }

    func signOutGoogleOnly() { // Renamed to avoid conflict if AuthenticationViewModel also has signOut
        GIDSignIn.sharedInstance.signOut()
        print("Google account signed out from GIDSignIn.")
    }
}

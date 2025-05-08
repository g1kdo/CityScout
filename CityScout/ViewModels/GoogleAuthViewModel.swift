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
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage: String = ""
    @Published var user: User?
    @Published var displayName: String = ""

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        registerAuthStateHandler()
    }

    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.displayName ?? ""
            }
        }
    }

    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Client ID not found in Firebase configuration."
            return false
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Root view controller not found."
            return false
        }

        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = userAuthentication.user.idToken else {
                errorMessage = "ID token missing."
                return false
            }
            let accessToken = userAuthentication.user.accessToken

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: accessToken.tokenString
            )

            let result = try await Auth.auth().signIn(with: credential)
            self.user = result.user
            self.authenticationState = .authenticated
            self.displayName = result.user.displayName ?? ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            authenticationState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

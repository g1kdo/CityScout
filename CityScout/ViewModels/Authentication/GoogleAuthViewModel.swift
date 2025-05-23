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
    @Published var signedInUser: SignedInUser?
    @Published var displayName: String = "" 

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        registerAuthStateHandler()
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
                guard let self = self else { return }
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.displayName ?? ""

                if let firebaseUser = user {
                    self.signedInUser = SignedInUser(
                        id: firebaseUser.uid,
                        displayName: firebaseUser.displayName,
                        email: firebaseUser.email ?? "(unknown email)"
                    )
                } else {
                    self.signedInUser = nil
                }
            }
        }
    }

    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Client ID not found in Firebase configuration. Make sure GoogleService-Info.plist is correctly set up."
            return false
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Root view controller not found for Google Sign-In presentation."
            return false
        }

        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = userAuthentication.user.idToken else {
                errorMessage = "Google ID token missing after sign-in."
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

            // Populate your custom SignedInUser object
            self.signedInUser = SignedInUser(
                id: result.user.uid,
                displayName: result.user.displayName,
                email: result.user.email ?? "(unknown email)"
            )
            return true
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            authenticationState = .unauthenticated
            self.signedInUser = nil
            return false
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            authenticationState = .unauthenticated
            self.signedInUser = nil
            self.user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

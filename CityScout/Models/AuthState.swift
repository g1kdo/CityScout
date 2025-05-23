//
//  AuthenticationState.swift
//  CityScout
//
//  Created by Umuco Auca on 22/05/2025.
//


import Foundation
import FirebaseAuth

class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var currentUser: SignedInUser?

    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Initialize based on current Firebase auth state
        _isAuthenticated = .init(initialValue: Auth.auth().currentUser != nil)
        _currentUser = .init(initialValue: Auth.auth().currentUser.map { SignedInUser(firebaseUser: $0) })

        // Set up the Firebase Auth state listener
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                guard let self = self else { return } // Safely unwrap self

                if let firebaseUser = user {
                    self.isAuthenticated = true
                    self.currentUser = SignedInUser(firebaseUser: firebaseUser)
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

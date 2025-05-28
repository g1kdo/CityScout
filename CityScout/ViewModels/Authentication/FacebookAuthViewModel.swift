//
//  FacebookAuthViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import FacebookCore // Make sure FacebookCore is imported for GraphRequest

@MainActor
class FacebookAuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    @Published var facebookUserName: String?
    @Published var facebookUserProfilePictureURL: URL?

    func signInWithFacebook() async -> FirebaseAuth.User? {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            facebookUserName = nil // Clear previous data
            facebookUserProfilePictureURL = nil // Clear previous data
        }

        return await performFacebookLogin()
    }

    private func performFacebookLogin() async -> FirebaseAuth.User? {
        return await withCheckedContinuation { continuation in
            let loginManager = LoginManager()

            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                Task { @MainActor in
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Facebook Login Error: \(error.localizedDescription)"
                        print("Facebook Login Error: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                        return
                    }

                    guard let result = result, !result.isCancelled else {
                        self.errorMessage = "Facebook login cancelled."
                        print("Facebook login cancelled.")
                        continuation.resume(returning: nil)
                        return
                    }

                    if result.declinedPermissions.contains("email") {
                        self.errorMessage = "Facebook: Email permission was declined. Some app functionality might be limited."
                        print("Facebook: Email permission was explicitly declined by the user.")
                    }

                    guard let accessToken = result.token?.tokenString else {
                        self.errorMessage = "Facebook access token not found."
                        print("Facebook access token not found.")
                        continuation.resume(returning: nil)
                        return
                    }

                    let facebookProfile = await self.fetchFacebookUserProfile()
                    self.facebookUserName = facebookProfile?.name
                    self.facebookUserProfilePictureURL = facebookProfile?.profilePictureURL
                    print("Fetched Facebook User Name: \(self.facebookUserName ?? "N/A")")
                    print("Fetched Facebook Profile Picture URL: \(self.facebookUserProfilePictureURL?.absoluteString ?? "N/A")")

                    let firebaseUser = await self.authenticateFirebaseWithFacebook(accessToken: accessToken)
                    continuation.resume(returning: firebaseUser)
                }
            }
        }
    }

    private func authenticateFirebaseWithFacebook(accessToken: String) async -> FirebaseAuth.User? {
        await MainActor.run {
            errorMessage = ""
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            print("Successfully signed in with Facebook and Firebase!")

            print("Firebase User Display Name: \(authResult.user.displayName ?? "N/A")")
            print("Firebase User Photo URL: \(authResult.user.photoURL?.absoluteString ?? "N/A")")


            return authResult.user // Return the Firebase User
        } catch {
            errorMessage = "Firebase Facebook Auth Error: \(error.localizedDescription)"
            print("Firebase Facebook Auth Error: \(error.localizedDescription)")
            return nil
        }
    }


    private func fetchFacebookUserProfile() async -> (name: String?, profilePictureURL: URL?)? {
        return await withCheckedContinuation { continuation in
            let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "name,picture.type(large)"])

            graphRequest.start { connection, result, error in
                if let error = error {
                    print("Graph API Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch Facebook profile: \(error.localizedDescription)"
                    continuation.resume(returning: nil)
                    return
                }

                if let result = result as? [String: Any] {
                    let name = result["name"] as? String

                    var profilePictureURL: URL?
                    if let pictureData = result["picture"] as? [String: Any],
                       let data = pictureData["data"] as? [String: Any],
                       let urlString = data["url"] as? String,
                       let url = URL(string: urlString) {
                        profilePictureURL = url
                    }

                    continuation.resume(returning: (name: name, profilePictureURL: profilePictureURL))
                } else {
                    print("Failed to parse Facebook Graph API response.")
                    self.errorMessage = "Failed to parse Facebook profile data."
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func signOutFacebookOnly() {
        LoginManager().logOut()
        print("Facebook account signed out from FBSDKLoginKit.")
        facebookUserName = nil
        facebookUserProfilePictureURL = nil
    }
}

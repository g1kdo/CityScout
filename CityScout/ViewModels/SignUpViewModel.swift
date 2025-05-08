//
//  SignUpViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var signedInUser: SignedInUser? = nil

    func signUpUser() async {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields must be filled."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let fbUser = result.user

            let profileChange = fbUser.createProfileChangeRequest()
            profileChange.displayName = fullName
            try await profileChange.commitChanges()

            signedInUser = SignedInUser(
                id: fbUser.uid,
                displayName: fullName,
                email: fbUser.email ?? "(unknown email)"
            )
        } catch {
            errorMessage = error.localizedDescription
            signedInUser = nil
        }

        isLoading = false
    }
}

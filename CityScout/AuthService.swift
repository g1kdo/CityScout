////
////  AuthService.swift
////  CityScout
////
////  Created by Umuco Auca on 24/04/2025.
////
//
//
//import Foundation
//import Firebase
//import GoogleSignIn
//import FBSDKLoginKit
//import AuthenticationServices
//
//class AuthService {
//
//    static let shared = AuthService()
//
//    // MARK: - Google Sign-In
//    func signInWithGoogle(from viewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
//        guard let clientID = FirebaseApp.app()?.options.clientID else {
//            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase clientID is missing"])))
//            return
//        }
//
//        let configuration = GIDConfiguration(clientID: clientID)
//
//        GIDSignIn.sharedInstance.signIn(withPresenting: viewController, with: configuration, hint: nil, additionalScopes: []) { user, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let user = user, let authentication = user.authentication else {
//                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User or authentication data is missing"])))
//                return
//            }
//
//            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
//
//            Auth.auth().signIn(with: credential) { authResult, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                completion(.success(authResult?.user ?? User()))
//            }
//        }
//    }
//
//    // MARK: - Facebook Sign-In
//    func signInWithFacebook(from viewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
//        let manager = LoginManager()
//
//        manager.logIn(permissions: ["email"], from: viewController) { result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let result = result, !result.isCancelled else {
//                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Facebook login was cancelled"])))
//                return
//            }
//
//            guard let token = AccessToken.current else {
//                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Facebook token is missing"])))
//                return
//            }
//
//            let credential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
//
//            Auth.auth().signIn(with: credential) { authResult, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                completion(.success(authResult?.user ?? User()))
//            }
//        }
//    }
//
//    // MARK: - Apple Sign-In
//    func signInWithApple(from viewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
//        let provider = ASAuthorizationAppleIDProvider()
//        let request = provider.createRequest()
//        request.requestedScopes = [.fullName, .email]
//
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = viewController as? ASAuthorizationControllerDelegate
//        controller.presentationContextProvider = viewController as? ASAuthorizationControllerPresentationContextProviding
//        controller.performRequests()
//
//        // Handle callback via delegate methods
//    }
//}

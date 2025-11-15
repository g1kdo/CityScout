//
//  PartnerSettingsViewModel.swift
//  CityScout
//  (Place in ViewModels/PartnerProfile)
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class PartnerSettingsViewModel: ObservableObject {
    
    // This ViewModel is lean and only includes
    // functions for rating and sharing.
    
    init() {
        // No settings to load
    }
    
    // MARK: - Rate & Share
    
    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func shareApp() {
        // Make sure to replace YOUR_APP_ID with your actual App Store ID
        let appUrl = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!
        let activityViewController = UIActivityViewController(activityItems: ["Check out the CityScout app!", appUrl], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
}

//
//  PartnerSettingsView.swift
//  CityScout
//  (Place in Views/PartnerProfile)
//

import SwiftUI

struct PartnerSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PartnerSettingsViewModel()
    
    // State to present the static views
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingTermsOfService = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // --- Custom Header ---
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2).foregroundColor(.primary)
                            .padding().background(Circle().fill(Color(.systemGray6)))
                    }
                    Spacer()
                    Text("Settings").font(.title2.bold())
                    Spacer()
                    // A spacer to balance the left button
                    Image(systemName: "chevron.left").opacity(0)
                        .padding().background(Circle().fill(Color.clear))
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // --- Settings List ---
                Form {
                    // --- Support & Feedback ---
                    Section(header: Text("Support & Feedback")) {
                        
                        ProfileOptionRow(icon: "star", title: "Rate This App", showChevron: true) {
                            viewModel.rateApp()
                        }

                        ProfileOptionRow(icon: "square.and.arrow.up", title: "Share This App", showChevron: true) {
                            viewModel.shareApp()
                        }
                    }
                    .foregroundColor(.primary)

                    // --- Legal ---
                    Section(header: Text("Legal")) {
                        
                        ProfileOptionRow(icon: "shield.hand", title: "Privacy Policy", showChevron: true) {
                            isShowingPrivacyPolicy = true
                        }

                        ProfileOptionRow(icon: "doc.text", title: "Terms of Service", showChevron: true) {
                            isShowingTermsOfService = true
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationBarHidden(true)
            // --- Modals for Policy and Terms ---
            .sheet(isPresented: $isShowingPrivacyPolicy) {
                PartnerPrivacyPolicyView()
            }
            .sheet(isPresented: $isShowingTermsOfService) {
                PartnerTermsOfServiceView()
            }
        }
    }
}

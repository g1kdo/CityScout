//
//  PartnerProfileView.swift
//  CityScout
//  (Place in a folder like CityScout/Views/PartnerProfile)
//

import SwiftUI
import Kingfisher

struct PartnerProfileView: View {
    @Environment(\.dismiss) var dismiss
    // Connects to the Partner's Auth VM
    @EnvironmentObject var authVM: PartnerAuthenticationViewModel
    
    // Uses the new PartnerProfileViewModel
    @StateObject var viewModel = PartnerProfileViewModel()
    
    @State private var isShowingEditPartnerProfile = false
    @State private var isShowingSettings = false
  

  
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        profileInfoSection
                        actionButtonsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .navigationBarHidden(true)
                .fullScreenCover(isPresented: $isShowingEditPartnerProfile) {
                    EditPartnerProfileView(viewModel: viewModel)
                        .environmentObject(authVM)
                }
                // --- ADD THIS MODIFIER ---
                .fullScreenCover(isPresented: $isShowingSettings) {
                    PartnerSettingsView()
                }
                // --- End of added modifier ---
            }
            .onAppear {
                viewModel.setup(with: authVM.signedInPartner)
            }
            .onChange(of: authVM.signedInPartner) { _, newPartner in
                viewModel.setup(with: newPartner)
            }
        }

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title2).foregroundColor(.primary)
                    .padding().background(Circle().fill(Color(.systemGray6)))
            }
            Spacer()
            Text("Partner Profile").font(.title2.bold())
            Spacer()
            Button { isShowingEditPartnerProfile = true } label: {
                Image(systemName: "pencil")
                    .font(.title2).foregroundColor(.primary)
                    .padding().background(Circle().fill(Color(.systemGray6)))
            }
        }
    }

    private var profileInfoSection: some View {
        VStack(spacing: 10) {
            // --- THIS IS THE FIX ---
            // Convert the String? to a URL? for KFImage
            KFImage(URL(string: authVM.signedInPartner?.profilePictureURL ?? ""))
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray) }
                .resizable().scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))

            Text(authVM.signedInPartner?.partnerDisplayName ?? "Partner Name")
                .font(.title.bold())
            
            Text(authVM.signedInPartner?.partnerEmail ?? "no-email@example.com")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

   
        private var actionButtonsSection: some View {
            VStack(spacing: 15) {
              
                
                // --- THIS ROW IS NOW FUNCTIONAL ---
                ProfileOptionRow(icon: "gear", title: "Settings") {
                    isShowingSettings = true
                }
                // --- End of change ---
                
                ProfileOptionRow(icon: "info.circle", title: "Version", showChevron: false) {}
                    .overlay(Text("1.0.0").font(.subheadline).foregroundColor(.secondary), alignment: .trailing)
                
                Spacer()

                Button {
                    authVM.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
            }
        }
}

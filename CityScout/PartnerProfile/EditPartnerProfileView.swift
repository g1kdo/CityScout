//
//  EditPartnerProfileView.swift
//  CityScout
//  (Place in a folder like CityScout/Views/PartnerProfile)
//

import SwiftUI
import PhotosUI
import CoreLocation
import Kingfisher

struct EditPartnerProfileView: View {
    @Environment(\.dismiss) var dismiss
    // Connects to the Partner's Auth VM
    @EnvironmentObject var authVM: PartnerAuthenticationViewModel
    // Uses the new PartnerProfileViewModel
    @ObservedObject var viewModel: PartnerProfileViewModel
    
    @State private var showingSaveAlert = false

    // State object for managing location services (copied from EditProfileView)
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    headerSection
                    profilePictureSection
                    fieldsSection
                    saveButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .alert("Profile Update", isPresented: $showingSaveAlert) {
                Button("OK") {
                    if viewModel.errorMessage.isEmpty {
                        // Dismiss the edit sheet
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.errorMessage.isEmpty ? "Your partner profile has been updated." : viewModel.errorMessage)
            }
            .alert("Location Access", isPresented: $showingLocationAlert) {
                Button("OK") { }
                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } message: {
                Text(locationManager.locationError ?? "Please enable location services in Settings.")
            }
        }
        .onAppear {
            viewModel.setup(with: authVM.signedInPartner)
            locationManager.requestLocationAuthorization()
        }
        .onChange(of: authVM.signedInPartner) { _, newPartner in
            viewModel.setup(with: newPartner)
        }
        .onChange(of: locationManager.locationString) { _, newLocation in
            if let newLocation = newLocation, !newLocation.isEmpty {
                viewModel.location = newLocation
                locationManager.stopUpdatingLocation()
            }
        }
        .onChange(of: locationManager.locationError) { _, newError in
            if newError != nil {
                showingLocationAlert = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title2).foregroundColor(.primary)
                    .padding().background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
            }
            Spacer()
            Text("Edit Partner Profile").font(.title2.bold())
            Spacer()
            Button {
                Task { await saveProfile() }
            } label: {
                Text("Done")
                    .font(.body.bold())
                    .foregroundColor(Color(hex: "#24BAEC"))
            }
        }
        .padding(.horizontal)
    }

    // This section is identical to EditProfileView and works because
    // the logic is encapsulated in the PartnerProfileViewModel.
    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.profileImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else if let url = viewModel.currentProfileImageURL {
                    KFImage(url)
                        .placeholder { Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 120, height: 120).foregroundColor(.gray) }
                        .resizable().scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable().scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }

                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable().scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color.white)
                        .background(Color.black)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                }
                .offset(x: 5, y: 5)
            }

            Text(viewModel.partnerDisplayName.isEmpty ? "Your Business Name" : viewModel.partnerDisplayName)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocationAuthorization()
                } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                } else {
                    locationManager.locationError = "Location access denied. Please enable it in Settings."
                    showingLocationAlert = true
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#FF7029"))
                    Text(locationManager.isLoadingLocation ? "Fetching Location..." : "Get Current Location")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "#FF7029"))
                }
            }
            .disabled(locationManager.isLoadingLocation)
            .opacity(locationManager.isLoadingLocation ? 0.6 : 1.0)
            .padding(.top, 0)
            .padding(.bottom, 10)

            if let error = locationManager.locationError, !error.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.top, 0)
            }
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 20) {
            // Binds to the properties in PartnerProfileViewModel
            FloatingField(
                label: "Partner/Business Name",
                placeholder: "Enter your business name",
                text: $viewModel.partnerDisplayName
            )
            .autocapitalization(.words)

            FloatingField(
                label: "Location",
                placeholder: "e.g., Kigali, Rwanda",
                text: $viewModel.location
            )
            .autocapitalization(.words)

            FloatingField(
                label: "Mobile Number",
                placeholder: "e.g., +250 791 597 929",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad
            )
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveProfile() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Save Changes")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .padding(.top, 20)
    }

    private func saveProfile() async {
        let success = await viewModel.updateProfile()
        if success {
            // We need to tell the authVM to refresh its data
            // This requires adding the 'refreshPartnerData' function
            // to PartnerAuthenticationViewModel
            await authVM.refreshPartnerData()
        }
        showingSaveAlert = true
    }
}

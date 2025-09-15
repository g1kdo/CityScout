// Views/EditProfileView.swift
import SwiftUI
import PhotosUI
import CoreLocation
import Kingfisher

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingSaveAlert = false

    // State object for managing location services
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationAlert = false // For location permission/error alerts

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    headerSection
                    profilePictureSection // This section will now handle photo editing
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
                        Task {
                            await authVM.refreshSignedInUserFromFirestore()
                        }
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.errorMessage.isEmpty ? "Your profile has been updated successfully." : viewModel.errorMessage)
            }
            // Alert for location errors/permissions
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
            // Setup ProfileViewModel with the current user from AuthenticationViewModel
            viewModel.setup(with: authVM.signedInUser)
            // Request location authorization when the view appears
            locationManager.requestLocationAuthorization()
        }
        // Observe changes to authVM.signedInUser to refresh edit fields if external changes occur
        .onChange(of: authVM.signedInUser) { oldUser, newUser in
            if let user = newUser {
                viewModel.setup(with: user)
            }
        }
        // Observe changes in LocationManager's locationString to update viewModel.location
        .onChange(of: locationManager.locationString) { oldLocation, newLocation in
            if let newLocation = newLocation, !newLocation.isEmpty {
                viewModel.location = newLocation
                locationManager.stopUpdatingLocation() // Stop updates once location is set
            }
        }
        // Observe location errors to show an alert
        .onChange(of: locationManager.locationError) { oldError, newError in
            if newError != nil {
                showingLocationAlert = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
            }

            Spacer()

            Text("Edit Profile")
                .font(.title2.bold())

            Spacer()

            Button {
                Task { await saveProfile() }
            } label: {
                Text("Done")
                    .font(.body.bold())
                    .foregroundColor(Color(hex: "#24BAEC")) // Assuming you have a Color(hex:) extension
            }
        }
        .padding(.horizontal)
    }

    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            // Profile Picture with overlayed edit button
            ZStack(alignment: .bottomTrailing) { // Use ZStack for overlay
                // The actual profile picture display logic
                if let image = viewModel.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else if let url = viewModel.currentProfileImageURL {
                    KFImage(url)
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }

                // The "pen" icon (PhotosPicker button)
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Image(systemName: "pencil.circle.fill") // Pen icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color.white)
                        .background(Color.black) 
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1)) // Subtle border
                }
                .offset(x: 5, y: 5) // Offset to position the icon
            }

            // Display current display name from viewModel
            Text(viewModel.displayName.isEmpty ? "Your Name" : viewModel.displayName)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Moved "Get Current Location" button here, styled as less noticeable text
            Button {
                // Request location when button is tapped
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocationAuthorization()
                } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                } else {
                    // If denied or restricted, show alert to guide user to settings
                    locationManager.locationError = "Location access denied. Please enable it in Settings."
                    showingLocationAlert = true
                }
            } label: {
                HStack(spacing: 5) { // Reduced spacing for a more compact look
                    Image(systemName: "location.fill")
                        .font(.caption) // Smaller icon
                        .foregroundColor(Color(hex: "#FF7029"))
                    Text(locationManager.isLoadingLocation ? "Fetching Location..." : "Get Current Location")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "#FF7029"))
                }
                .font(.caption) // Smaller font for the text
                .foregroundColor(.gray) // Gray color to make it less noticeable
            }
            .disabled(locationManager.isLoadingLocation) // Disable button while loading
            .opacity(locationManager.isLoadingLocation ? 0.6 : 1.0)
            .padding(.top, 0) // No top padding needed as it's directly below
            .padding(.bottom, 10) // Add padding to separate from fields below

            // Display location error if any (moved here from original locationButtonSection)
            if let error = locationManager.locationError, !error.isEmpty {
                Text(error)
                    .font(.caption2) // Even smaller font for error
                    .foregroundColor(.red)
                    .padding(.top, 0) // No top padding
            }
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 20) {
            FloatingField(
                label: "Full Name or Display Name",
                placeholder: "Enter your full name or display name",
                text: $viewModel.displayName // Now binding to displayName
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
                text: $viewModel.mobileNumber,
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
            .background(Color(hex: "#24BAEC")) // Assuming you have a Color(hex:) extension
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .padding(.top, 20)
    }

    private func saveProfile() async {
        // Pass the signedInUser from authVM to the updateProfile method
        _ = await viewModel.updateProfile(signedInUserFromAuthVM: authVM.signedInUser)
        showingSaveAlert = true
    }
}

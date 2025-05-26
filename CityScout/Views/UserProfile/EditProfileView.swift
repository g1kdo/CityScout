// Views/EditProfileView.swift
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel // Added for direct access
    @ObservedObject var viewModel: ProfileViewModel // Still use this for editing fields
    @State private var showingSaveAlert = false

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
                        // After successful save, also update authVM.signedInUser
                        // by forcing a refresh or passing updated data.
                        // For simplicity, let's assume authVM has a mechanism to refresh
                        // its signedInUser from Firebase Auth after a profile update.
                        // Or, you can explicitly call a refresh method:
                        // authVM.refreshSignedInUserFromFirebaseAuth()
                        // Or even simpler:
                       // $authVM.fetchUser // Assuming this method re-fetches user from Firebase Auth
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.errorMessage.isEmpty ? "Your profile has been updated successfully." : viewModel.errorMessage)
            }
        }
        .onAppear {
            // Setup ProfileViewModel with the current user from AuthenticationViewModel
            viewModel.setup(with: authVM.signedInUser)
        }
        // Observe changes to authVM.signedInUser to refresh edit fields if external changes occur
        .onChange(of: authVM.signedInUser) { oldUser, newUser in
            if let user = newUser {
                viewModel.setup(with: user)
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
                    .foregroundColor(Color(hex: "#24BAEC"))
            }
        }
        .padding(.horizontal)
    }

    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            // Display viewModel.profileImage (the selected/loaded image)
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
            } else {
                // Fallback to default if no image is selected/loaded
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }

            // Display current display name from authVM, or construct from local fields
            Text(authVM.signedInUser?.displayName ?? "\(viewModel.firstName) \(viewModel.lastName)".trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Text("Change Profile Picture")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "#FF7029"))
            }
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 20) {
            FloatingField(
                label: "First Name",
                placeholder: "Enter your first name",
                text: $viewModel.firstName
            )
            .autocapitalization(.words)

            FloatingField(
                label: "Last Name",
                placeholder: "Enter your last name",
                text: $viewModel.lastName
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
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .padding(.top, 20)
    }

    private func saveProfile() async {
        // Pass the signedInUser from authVM to the updateProfile method
        let success = await viewModel.updateProfile(signedInUserFromAuthVM: authVM.signedInUser)
        showingSaveAlert = true
    }
}

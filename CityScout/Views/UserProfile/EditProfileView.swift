// Views/EditProfileView.swift
import SwiftUI
import PhotosUI // For iOS 14+ photo picker

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss // To dismiss the sheet/fullScreenCover
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingSaveAlert = false // To show success/error after save

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
            .navigationBarHidden(true) // Hide default nav bar to use custom one
            .alert("Profile Update", isPresented: $showingSaveAlert) {
                Button("OK") {
                    if viewModel.errorMessage.isEmpty {
                        dismiss() // Dismiss if successful
                    }
                }
            } message: {
                Text(viewModel.errorMessage.isEmpty ? "Your profile has been updated successfully." : viewModel.errorMessage)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                dismiss() // Dismiss the sheet
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("Edit Profile")
                .font(.title2.bold())

            Spacer()

            Button {
                // "Done" button action, similar to Save
                Task { await saveProfile() }
            } label: {
                Text("Done")
                    .font(.body.bold())
                    .foregroundColor(Color(hex: "#24BAEC")) // Your app's primary color
            }
        }
        .padding(.horizontal)
    }

    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
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

            Text(viewModel.signedInUser.displayName ?? "\(viewModel.firstName) \(viewModel.lastName)".trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Text("Change Profile Picture")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "#FF7029")) // Your app's accent color
            }
            // Ensure this is only for iOS 14+ for PhotosPicker
            // For older iOS, you'd use UIImagePickerController
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
            .background(Color(hex: "#24BAEC")) // Your app's primary color
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .padding(.top, 20)
    }

    private func saveProfile() async {
        let success = await viewModel.updateProfile()
        showingSaveAlert = true // Always show alert after attempting save
    }
}
// Views/ProfileView.swift
import SwiftUI
import Kingfisher // Still using Kingfisher for loading images from URLs

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel // Access shared authentication state
    @StateObject var viewModel = ProfileViewModel() // Initialize without 'user'
    @State private var isShowingEditProfile = false


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
            .fullScreenCover(isPresented: $isShowingEditProfile) {
                // Pass the same viewModel, and inject authVM as environment
                EditProfileView(viewModel: viewModel)
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            // Setup ProfileViewModel with the current user from AuthenticationViewModel
            viewModel.setup(with: authVM.signedInUser)
        }
        .onChange(of: authVM.signedInUser?.id) { oldId, newId in
            // React to changes in the signedInUser from AuthenticationViewModel
            // If the user logs out (id becomes empty), handle navigation
            if newId == nil || newId?.isEmpty == true {
                // This `ProfileView` instance might not be the direct one navigating
                // the app to sign-in, but it reflects the state.
                // The parent (HomeView) will likely handle navigation to sign-in.
                print("User signed out from ProfileView. Handling transition if needed.")
            } else {
                // If the user re-authenticates or updates, refresh data
                viewModel.setup(with: authVM.signedInUser)
            }
        }
        // Observe changes to authVM.signedInUser to trigger UI updates for profile details
        .onChange(of: authVM.signedInUser) { oldUser, newUser in
            // This sink is crucial for ProfileView to react when AuthVM updates its user
            if let user = newUser {
                viewModel.setup(with: user) // Re-setup if the user object itself changes
            } else {
                // User logged out, clear local state if necessary
                viewModel.firstName = ""
                viewModel.lastName = ""
                viewModel.location = ""
                viewModel.mobileNumber = ""
                viewModel.profileImage = nil
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

            Text("Profile")
                .font(.title2.bold())

            Spacer()

            Button {
                isShowingEditProfile = true
            } label: {
                
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
            }
        }
        .padding(.horizontal)
    }

    private var profileInfoSection: some View {
        VStack(spacing: 10) {
            // Prefer viewModel.profileImage if set (from PhotosPicker or loaded from URL cache)
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
            }
            // Fallback to Kingfisher for URL from authVM if viewModel.profileImage isn't set
            else if let url = authVM.signedInUser?.profilePictureURL { // Use authVM for the URL
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
//                    .placeholder {
//                        Image(systemName: "person.circle.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 120, height: 120)
//                            .foregroundColor(.gray)
//                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }

            Text(authVM.signedInUser?.displayName ?? "\(viewModel.firstName) \(viewModel.lastName)".trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(authVM.signedInUser?.email ?? "N/A")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            ProfileOptionRow(icon: "person", title: "Profile") {
                // This might navigate to the same profile view (redundant for now)
            }
            ProfileOptionRow(icon: "bookmark", title: "Bookmarked") {
                // Navigate to bookmarked content
            }
            ProfileOptionRow(icon: "globe", title: "Previous Trips") {
                // Navigate to previous trips
            }
            ProfileOptionRow(icon: "gear", title: "Settings") {
                // Navigate to app settings
            }
            ProfileOptionRow(icon: "info.circle", title: "Version", showChevron: false) {
                // Display app version
            }
            .overlay(
                Text("1.0.0") // Replace with actual app version from Bundle
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 10),
                alignment: .trailing
            )

            Spacer()

            Button {
                viewModel.signOut() // This will clear the `Auth.auth().currentUser`
                authVM.signedInUser = nil // Manually set to nil to trigger UI change in AuthVM
                                            // (AuthVM usually handles this on its own, but explicit is fine)
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

// ProfileOptionRow remains unchanged
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(width: 25)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

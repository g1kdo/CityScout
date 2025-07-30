// Views/ProfileView.swift
import SwiftUI
import Kingfisher
import FirebaseStorage // ADD THIS IMPORT // For potential direct image loading or caching

// MARK: - ProfileOptionRow
// This struct defines a reusable row for profile options,
// including an icon, title, and an optional chevron.


// MARK: - ProfileView
struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var viewModel = ProfileViewModel()
    @State private var isShowingEditProfile = false
    @State private var isShowingBookmarked = false

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
                EditProfileView(viewModel: viewModel)
                    .environmentObject(authVM)
            }
            .fullScreenCover(isPresented: $isShowingBookmarked) {
                FavoritePlacesView()
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            // Setup ProfileViewModel with the current user from AuthenticationViewModel
            viewModel.setup(with: authVM.signedInUser)
        }
        .onChange(of: authVM.signedInUser?.id) { oldId, newId in
            if newId == nil || newId?.isEmpty == true {
                print("User signed out from ProfileView. Handling transition if needed.")
            } else {
                // If the user re-authenticates or updates, refresh data
                viewModel.setup(with: authVM.signedInUser)
            }
        }
        .onChange(of: authVM.signedInUser) { oldUser, newUser in
            if let user = newUser {
                viewModel.setup(with: user) // Re-setup if the user object itself changes
            } else {
                // User logged out, clear local state if necessary
                viewModel.displayName = ""
                viewModel.location = ""
                viewModel.mobileNumber = ""
                viewModel.profileImage = nil
                viewModel.currentProfileImageURL = nil // Clear URL
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
            // Priority 1: Use the locally selected/loaded image if available (from PhotosPicker or Firebase Storage)
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
            }
            // Priority 2: Fallback to Kingfisher for the currentProfileImageURL (which could be from Firestore or social login)
            else if let url = viewModel.currentProfileImageURL { // Use viewModel's URL
                KFImage(url)
                    // Apply placeholder directly to KFImage before other modifiers
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
            }
            // Priority 3: Default placeholder image
            else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }

            // Display name logic: Prioritize user-set first/last name if available,
            // otherwise fall back to authVM.signedInUser?.displayName (from social login)
            Text({
                let fullName = "\(viewModel.displayName)".trimmingCharacters(in: .whitespacesAndNewlines)
                if !fullName.isEmpty {
                    return fullName
                } else {
                    return authVM.signedInUser?.displayName ?? "User Name" // Fallback if no names set
                }
            }())
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
                isShowingBookmarked = true
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
                viewModel.signOut()
                authVM.signedInUser = nil // Manually set to nil to trigger UI change in AuthVM
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

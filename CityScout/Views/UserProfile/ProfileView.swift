// Views/ProfileView.swift
import SwiftUI
import Kingfisher // For loading images from URL (add to Project dependencies if you haven't)

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var isShowingEditProfile = false
    @Binding var shouldNavigateToSignIn: Bool // For signing out

    init(user: SignedInUser, shouldNavigateToSignIn: Binding<Bool>) {
        _viewModel = ObservedObject(wrappedValue: ProfileViewModel(user: user))
        _shouldNavigateToSignIn = shouldNavigateToSignIn
    }

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
            .navigationBarHidden(true) // Hide default nav bar to use custom one
            .fullScreenCover(isPresented: $isShowingEditProfile) {
                EditProfileView(viewModel: viewModel) // Pass the same viewModel
            }
        }
        .onChange(of: viewModel.signedInUser) { oldUser, newUser in
            // React to changes in signedInUser, e.g., if it becomes nil after sign out
            if newUser.id.isEmpty { // Assuming id is empty when signed out
                shouldNavigateToSignIn = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                // Handle back action (if this view is pushed)
                // If it's a root view, this might not do anything or navigate to a dashboard
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .opacity(0) // Hide for now as per design, but keep button structure

            Spacer()

            Text("Profile")
                .font(.title2.bold())

            Spacer()

            Button {
                isShowingEditProfile = true // Show edit profile sheet/fullScreenCover
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
    }

    private var profileInfoSection: some View {
        VStack(spacing: 10) {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
            } else if let url = viewModel.signedInUser.profilePictureURL {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }

            Text(viewModel.signedInUser.displayName ?? "\(viewModel.signedInUser.firstName ?? "") \(viewModel.signedInUser.lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(viewModel.signedInUser.email)
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            ProfileOptionRow(icon: "person", title: "Profile") {
                // This might navigate to the same profile view (redundant for now)
                // Or if there are sub-sections of profile.
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
                // For "Version", show the version number
                Text("1.0.0") // Replace with actual app version from Bundle
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 10),
                alignment: .trailing
            )

            Spacer()

            Button {
                viewModel.signOut()
                // shouldNavigateToSignIn will be set to true by the onChange observer
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red) // Use a distinct color for sign out
                .cornerRadius(10)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Reusable Profile Option Row
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
                    .frame(width: 25) // Fixed width for alignment

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
            .background(Color.white) // Or your app's background color for cards
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) // Subtle shadow
        }
    }
}

// If Kingfisher isn't used or for previews, you might need a placeholder or
// simple async image loader. For this example, Kingfisher is assumed.
// You'll need to add Kingfisher to your project (via SPM or CocoaPods).
// Example SPM: File > Add Packages... > search for "https://github.com/onevcat/Kingfisher.git"
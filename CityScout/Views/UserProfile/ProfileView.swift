import SwiftUI
import Kingfisher

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    // The viewModel is created here, so it doesn't need to be passed in from HomeView.
    @StateObject var viewModel = ProfileViewModel(reviewViewModel: ReviewViewModel())
    
    // State variables to control navigation to the new and existing screens
    @State private var isShowingEditProfile = false
    @State private var isShowingBookmarked = false
    @State private var isShowingSettings = false
    @State private var isShowingPreviousTrips = false

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
            // --- MODIFIERS TO PRESENT THE NEW VIEWS ---
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingPreviousTrips) {
                PreviousTripsView().environmentObject(authVM)
            }
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
            viewModel.setup(with: authVM.signedInUser)
        }
        .onChange(of: authVM.signedInUser) { _, newUser in
            viewModel.setup(with: newUser)
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
            Text("Profile").font(.title2.bold())
            Spacer()
            Button { isShowingEditProfile = true } label: {
                Image(systemName: "pencil")
                    .font(.title2).foregroundColor(.primary)
                    .padding().background(Circle().fill(Color(.systemGray6)))
            }
        }
    }

    private var profileInfoSection: some View {
        VStack(spacing: 10) {
            KFImage(authVM.signedInUser?.profilePictureAsURL)
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray) }
                .resizable().scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))

            Text(authVM.signedInUser?.displayName ?? "User Name")
                .font(.title.bold())
            
            Text(authVM.signedInUser?.email ?? "no-email@example.com")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            ProfileOptionRow(icon: "bookmark", title: "Bookmarked") {
                isShowingBookmarked = true
            }
            // --- FUNCTIONAL ROW ---
            ProfileOptionRow(icon: "globe", title: "Previous Trips") {
                isShowingPreviousTrips = true
            }
            // --- FUNCTIONAL ROW ---
            ProfileOptionRow(icon: "gear", title: "Settings") {
                isShowingSettings = true
            }
            
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

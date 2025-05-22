import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                headlineSection
                sectionHeader
                carouselSection
                
                Spacer()
                FooterView()
            }
            .padding(.top, safeAreaTop())
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                Task { await vm.loadDestinations() }
            }
        }
    }

    private var topBar: some View {
        HStack {
            if let user = authVM.user {
                HStack(spacing: 8) {
                    Image("LocalAvatarName")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    Text(user.displayName ?? "User")
                        .font(.subheadline).bold()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            } else {
                ProgressView()
                    .frame(width: 36, height: 36)
            }
            Spacer()
            // Inside your topBar:
            NotificationBell(unreadCount: 0)


        }
        .padding(.horizontal)
       
    }

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Explore the")
                .font(.largeTitle)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Beautiful ")
                    .font(.largeTitle).bold()
                VStack(alignment: .leading, spacing: 2) {
                    Text("world!")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color(hex: "#FF7029"))
                    Image("Line")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 15)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var sectionHeader: some View {
        HStack {
            Text("Best Destinations")
                .font(.headline).bold()
            Spacer()
            Button("View all") {}
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
        }
        .padding(.horizontal)
        .padding(.top, 30)
    }

    private var carouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(vm.destinations) { dest in
                    DestinationCard(destination: dest)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func safeAreaTop() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows.first?
            .safeAreaInsets.top ?? 0
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel())
}

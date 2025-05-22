import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = HomeViewModel()
    @State private var selectedTab: FooterTab = .home

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Top Bar
                TopBarView()
                    .environmentObject(authVM)
                    .padding(.bottom, 25) // Custom bottom spacing for top bar

                // Headline Section
                headlineSection
                    .padding(.bottom, 25) // Spacing below headline

                // Section Header
                sectionHeader
                    .padding(.bottom, 35) // Spacing below section header

                // Carousel Section
                carouselSection
                    .padding(.bottom, 65) // Spacing below carousel

                Spacer()

                // Footer
                FooterView(selected: $selectedTab)
            }
            .padding(.top, safeAreaTop()) // Keep safe area padding at the top
            .background(Color.white).ignoresSafeArea()
            .navigationBarHidden(true)
            .onAppear {
                Task { await vm.loadDestinations() }
            }
        }
    }

    // MARK: Headline—flush left
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }

    // MARK: Section Header
    private var sectionHeader: some View {
        HStack {
            Text("Best Destinations")
                .font(.headline).bold()
            Spacer()
            Button("View all") { }
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
        }
        .padding(.horizontal)
    }

    // MARK: Carousel
    private var carouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(vm.destinations) { dest in
                    DestinationCard(destination: dest)
                }
            }
            .padding(.horizontal)
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

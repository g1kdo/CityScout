import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = HomeViewModel()
    @State private var navigateToProfile = false
    @State private var selectedDestination: Destination?
    @State private var selectedTab: FooterTab = .home

    @State private var showSearchView: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    TopBarView()
                        .environmentObject(authVM)
                        .padding(.bottom, 25)

                    currentTabView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    FooterView(selected: $selectedTab)
                }
                .padding(.top, safeAreaTop())
                .background(Color.white).ignoresSafeArea()
                .navigationBarHidden(true)

                // 🔐 Hidden navigation trigger for ProfileView
                NavigationLink(
                    destination: ProfileView().environmentObject(authVM),
                    isActive: $navigateToProfile,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .onChange(of: selectedTab) { oldValue, newTab in
                if newTab == .profile {
                    navigateToProfile = true
                } else if newTab == .search {
                    showSearchView = true
                    // No need to set selectedTab here, it's already .search
                }
            }
            .onChange(of: navigateToProfile) { oldValue, isActive in
                if !isActive {
                    selectedTab = .home
                }
            }
            // MARK: NEW: Add onChange for showSearchView
            .onChange(of: showSearchView) { oldValue, isPresented in
                if !isPresented {
                    selectedTab = .home
                }
            }
            .onAppear {
                Task { await vm.loadDestinations() }
            }
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedDestination != nil },
                set: { if !$0 { selectedDestination = nil } }
            )) {
                if let dest = selectedDestination {
                    DestinationDetailView(destination: dest)
                }
            }
            .fullScreenCover(isPresented: $showSearchView){
                SearchView()
                    .environmentObject(vm)
            }
        }
    }

    // Your existing HomeView sections go here, unchanged:
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
                    Button(action: {
                        selectedDestination = dest
                    }) {
                        DestinationCard(destination: dest)
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent default button style interference
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

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            VStack(spacing: 0) {
                headlineSection
                    .padding(.bottom, 25)
                sectionHeader
                    .padding(.bottom, 35)
                carouselSection
                    .padding(.bottom, 65)
                Spacer()
            }
        case .calendar:
            VStack {
                ScheduleView()
                Spacer()
            }
        case .search:
            Color.clear
        case .saved:
            VStack {
                Text("Saved View Content")
                Spacer()
            }
        case .profile:
            Color.clear
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel())
}

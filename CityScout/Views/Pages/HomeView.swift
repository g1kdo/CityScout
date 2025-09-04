import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = HomeViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var navigateToProfile = false
    @State private var selectedDestination: Destination?
    @State private var selectedTab: FooterTab = .home
    
    // --- NEW STATE VARIABLE ---
    // The state for messages is now here and passed to the TopBarView
    @State private var isShowingMessagesView: Bool = false
    
    @State private var showPopularPlacesView: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Your main content
                VStack(spacing: 0) {
                    TopBarView(isShowingMessagesView: $isShowingMessagesView)
                        .environmentObject(authVM)
                        .padding(.bottom, 25)
                    
                    // This view now holds the content for the selected tab.
                    currentTabView
                    
                    // --- FIX IS HERE ---
                    // This Spacer is now part of the main layout. It will always
                    // expand to fill the remaining vertical space, pushing the
                    // FooterView to the bottom, regardless of which tab is selected.
                    Spacer()
                    
                    FooterView(selected: $selectedTab)
                }
                .padding(.top, safeAreaTop())
                .background(Color(.systemBackground)).ignoresSafeArea()
                
                // Layer 2 (Conditional): The Search View Overlay
                if vm.showSearchView {
                    SearchView()
                        .environmentObject(vm)
                        .environmentObject(favoritesVM)
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedTab) { oldValue, newTab in
                if newTab == .profile {
                    navigateToProfile = true
                } else if newTab == .search {
                    withAnimation {
                        vm.showSearchView = true
                    }
                }
                // --- NEW LOGIC: Handle navigation to MessagesView ---
                // The messaging view is now presented via a fullScreenCover
            }
            .onChange(of: navigateToProfile) { oldValue, isActive in
                if !isActive {
                    selectedTab = .home
                }
            }
            .onChange(of: vm.showSearchView) { _, isPresented in
                if !isPresented {
                    selectedTab = .home
                }
            }
            // --- NEW LOGIC: Reset tab if MessagesView is dismissed ---
            .onChange(of: isShowingMessagesView) { _, isPresented in
                if !isPresented {
                    selectedTab = .home
                }
            }
            .onChange(of: showPopularPlacesView) { oldValue, isPresented in
                if !isPresented {
                    selectedTab = .home
                }
            }
            .onAppear {
                favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
            }
            .onChange(of: authVM.user?.uid) { oldValue, newUserId in
                favoritesVM.subscribeToFavorites(for: newUserId)
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView(viewModel: ProfileViewModel(reviewViewModel: ReviewViewModel()))
                    .environmentObject(authVM)
            }
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedDestination != nil },
                set: { if !$0 { selectedDestination = nil } }
            )) {
                if let dest = selectedDestination {
                    DestinationDetailView(destination: dest)
                }
            }
            .navigationDestination(isPresented: $showPopularPlacesView) {
                PopularPlacesView()
                    .environmentObject(vm)
            }
            // --- NEW: Navigation to MessagesView ---
            .navigationDestination(isPresented: $isShowingMessagesView) {
                MessagesView()
                    .environmentObject(authVM)
            }
        }
        .environmentObject(vm)
        .environmentObject(favoritesVM)
    }
    
    // All of your private vars (headlineSection, sectionHeader, etc.)
    // remain the same.
    
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
    
    private var sectionHeader: some View {
        HStack {
            Text("Best Destinations")
                .font(.headline).bold()
            Spacer()
            Button("View all") {
                showPopularPlacesView = true
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "#FF7029"))
        }
        .padding(.horizontal)
    }
    
    private var carouselSection: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.destinations) { dest in
                        Button(action: {
                            selectedDestination = dest
                        }) {
                            HomeDestinationCard(
                                destination: dest,
                                isFavorite: favoritesVM.isFavorite(destination: dest)
                            ) {
                                Task {
                                    await favoritesVM.toggleFavorite(destination: dest)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
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
        // --- FIX IS HERE ---
        // The individual Spacers have been removed from each case.
        // The content of each view will now naturally sit at the top of its available space.
        switch selectedTab {
        case .home:
            // This is now a ScrollView to ensure its content can grow without
            // pushing the footer away if it becomes very long.
            ScrollView {
                VStack(spacing: 0) {
                    headlineSection
                        .padding(.bottom, 25)
                    sectionHeader
                        .padding(.bottom, 35)
                    
                    if vm.isLoading {
                        ProgressView("Loading Destinations...")
                            .frame(height: 300)
                    } else if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else {
                        carouselSection
                            .padding(.bottom, 65)
                    }
                }
            }
        case .calendar:
            ScheduleView()
        case .search:
            Color.clear
        case .review:
            ReviewView()
                .environmentObject(vm)
                .environmentObject(favoritesVM)
               
        case .profile:
            Color.clear
        }
    }
}

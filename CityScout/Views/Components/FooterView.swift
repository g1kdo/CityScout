import SwiftUI

/// The tabs available in the footer bar
enum FooterTab: Int, CaseIterable {
    case home, calendar, search, saved, profile
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .search: return "magnifyingglass"
        case .saved: return "bookmark.fill"
        case .profile: return "person.crop.circle"
        }
    }
    var title: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .search: return "Search"
        case .saved: return "Saved"
        case .profile: return "Profile"
        }
    }
}

struct FooterView: View {
    @State private var selectedTab: FooterTab = .home

    var body: some View {
        HStack {
            ForEach(FooterTab.allCases, id: \ .self) { tab in
                FooterButton(
                    iconName: tab.iconName,
                    title: tab.title,
                    isSelected: tab == selectedTab
                ) {
                    selectedTab = tab
                    // TODO: handle tab action/navigation here
                }
                if tab != FooterTab.allCases.last {
                    Spacer()
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
    }
}

private struct FooterButton: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#24BAEC") : .gray)
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color(hex: "#24BAEC") : .gray)
            }
        }
    }
}




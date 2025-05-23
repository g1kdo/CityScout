import SwiftUI

// Helper to round only top corners
struct RoundedTopShape: Shape {
    var radius: CGFloat = 30
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: radius))
        p.addQuadCurve(to: CGPoint(x: radius, y: 0),
                       control: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        p.addQuadCurve(to: CGPoint(x: rect.width, y: radius),
                       control: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

enum FooterTab: CaseIterable {
    case home, calendar, search, saved, profile
    var iconName: String {
        switch self {
        case .home:      return "house"
        case .calendar:  return "calendar"
        case .search:    return "magnifyingglass"
        case .saved:  return "bookmark.fill"
        case .profile:   return "person.crop.circle"
        }
    }
    var title: String {
        switch self {
        case .home:     return "Home"
        case .calendar: return "Calendar"
        case .search:   return ""
        case .saved: return "Saved"
        case .profile:  return "Profile"
        }
    }
}

struct FooterView: View {
    @Binding var selected: FooterTab

    var body: some View {
        HStack {
            ForEach(FooterTab.allCases, id: \.self) { tab in
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: tab == .search ? 0 : 4) {
                        ZStack {
                            if tab == .search {
                                Circle()
                                    .fill(Color(hex: "#24BAEC"))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(hex: "#24BAEC").opacity(0.3),
                                            radius: 10, x: 0, y: 4)
                            }
                            Image(systemName: tab.iconName)
                                .font(.system(size: tab == .search ? 30 : 26))
                                .foregroundColor(
                                    tab == .search
                                      ? .white
                                      : (selected == tab ? Color(hex: "#24BAEC") : .gray)
                                )
                        }
                        if tab != .search {
                            Text(tab.title)
                                .font(.caption2)
                                .foregroundColor(selected == tab
                                                   ? Color(hex: "#24BAEC")
                                                   : .gray)
                        }
                    }
                }
                if tab != FooterTab.allCases.last {
                    Spacer()
                   
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, safeAreaBottom() + 5)
        .background(
            RoundedTopShape(radius: 50)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05),
                        radius: 8, x: 0, y: -2)
        )
    }

    private func safeAreaBottom() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows.first?
            .safeAreaInsets.bottom ?? 0
    }
}

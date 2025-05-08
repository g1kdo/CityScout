import SwiftUI
@testable import CityScout   // if you need access to models; otherwise just `import SwiftUI`

struct HomeView: View {
  let user: SignedInUser

  var body: some View {
    VStack(spacing: 16) {
      Text("🎉 Welcome, \(user.displayName)!")
        .font(.largeTitle.bold())
      Text("Email: \(user.email)")
      Text("UID: \(user.id)")
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}



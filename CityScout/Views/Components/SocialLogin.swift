import SwiftUI

enum SocialProvider { case google, facebook, apple }

struct SocialLoginButton: View {
    let provider: SocialProvider
    let action: () -> Void

    private var imageName: String {
        switch provider {
        case .google:   return "google_logo"
        case .facebook: return "facebook_logo"
        case .apple:    return "apple_logo"
        }
    }
    private var size: CGSize {
        provider == .apple
          ? CGSize(width: 37, height: 42)
          : CGSize(width: 40, height: 40)
    }

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .frame(width: size.width, height: size.height)
        }
    }
}



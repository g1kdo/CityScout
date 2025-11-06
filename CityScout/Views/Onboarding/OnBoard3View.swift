import SwiftUI

struct OnBoard3View: View {
    
    @State private var isSignInActive = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var titleFont: Font {
        let size: CGFloat = (horizontalSizeClass == .regular) ? 34 : 26
        return .system(size: size)
    }
    
    private var bodyFont: Font {
        let size: CGFloat = (horizontalSizeClass == .regular) ? 20 : 16
        return .system(size: size)
    }
    private var lineWidth: CGFloat {
            return (horizontalSizeClass == .regular) ? 100 : 60 // 90 for iPad, 60 for iPhone
        }
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        // ... Image and Skip Button code ...
                        Image("OnBoard3")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
                            .clipped()
                            .ignoresSafeArea(edges: .top)

                        Button(action: {
                            print("Skip Tapped")
                            navigateToSignIn()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .padding(.top, 10.0)
                        .padding(.trailing, 20)
                    }

                    VStack(spacing: 10) {
                        VStack(spacing: 4) {
                            Text("People don't take trips, trips take")
                                .font(titleFont)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7) // <-- ADD THIS

                            Text("people")
                                .font(titleFont)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#FF7029"))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7) // <-- ADD THIS

                            Image("Line")
                            .resizable()
                            .scaledToFit()
                            .frame(width: lineWidth, height: 10)
                        }
                        .padding(.horizontal, 30.0)
                        .padding(.top, 30)

                        Text("To get the best of your adventure you just need to leave and go where you like. We are waiting for you")
                            .font(bodyFont)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .minimumScaleFactor(0.7) // <-- ADD THIS

                        Spacer()
                            
                        OnboardingPageIndicator(pageCount: 3, currentIndex: 2)
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                            
                        PrimaryButton(title: "Get Started", action: navigateToSignIn)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isSignInActive) {
                SignInView()
            }
        }
    }

    private func navigateToSignIn() {
        isSignInActive = true
    }
}

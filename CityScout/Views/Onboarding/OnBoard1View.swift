//
//  OnBoard1View.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct OnBoard1View: View {
    
    @State private var isOnBoarding2Active = false
    @State private var isSignInActive = false
    
    var body: some View {
        NavigationStack { // Use a NavigationStack to ensure full-screen cover works correctly
            ZStack(alignment: .topTrailing) {
                
                // 1. DYNAMIC BACKGROUND: Use systemBackground for the main view
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Image("OnBoard1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
                            .clipped()
                            .ignoresSafeArea(edges: .top)

                        // Skip Button (needs to be visible against the image)
                        Button(action: {
                            print("Skip Tapped")
                            navigateToSignIn()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16))
                                // Text should remain white/light to contrast with the image
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .padding(.top, 10.0) // Pushed higher
                        .padding(.trailing, 20)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            VStack(spacing: 4) {
                                Text("Life is short and the world is")
                                    .font(.system(size: 26, weight: .heavy))
                                    // 2. DYNAMIC TEXT: Use .primary for main text
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text("wide")
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(Color(hex: "#FF7029")) // Brand color remains the same
                                    .multilineTextAlignment(.center)

                                Image("Line")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 10)
                                    // 3. IMAGE COLOR: The line image may need re-coloring
                                    // If it's pure black/white, it will auto-adapt.
                            }
                            .padding(.horizontal, 30.0)

                            Text("At Friends tours and travel, we customize reliable and trustworthy educational tours to destinations all over the world")
                                .font(.system(size: 16))
                                // 4. DYNAMIC SECONDARY TEXT: Use .secondary for descriptive text
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            OnboardingPageIndicator(pageCount: 3, currentIndex: 0)
                                .padding(.top, 10)
                                .padding(.bottom, 16)
                            
                            PrimaryButton(title: "Get Started", action: navigateToOnBoard2) // Assuming PrimaryButton handles its own colors
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isOnBoarding2Active) {
                OnBoard2View() // Assuming OnBoard2View also uses dynamic colors
            }
            .navigationDestination(isPresented: $isSignInActive) {
                SignInView()
            }
        }
    }

    private func navigateToOnBoard2() {
        isOnBoarding2Active = true
    }
    private func navigateToSignIn() {
        isSignInActive = true
    }
}


// MARK: - Extension and Helper Shapes (No changes needed)

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    OnBoard1View()
}

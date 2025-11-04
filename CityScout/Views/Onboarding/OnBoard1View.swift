//
//  OnBoard1View.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

// This extension provides the .cornerRadius(_:corners:) modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

// This Shape does the actual drawing
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
struct OnBoard1View: View {
    
    @State private var isOnBoarding2Active = false
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
                        Image("OnBoard1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(40, corners: [.bottomLeft, .bottomRight])
                            .clipped()
                            .ignoresSafeArea(edges: .top)

                        // Skip Button
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
                            Text("Life is short and the world is")
                                .font(titleFont)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7) // <-- ADD THIS

                            Text("wide")
                                .font(titleFont)
                                .fontWeight(.heavy)
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

                        Text("At Friends tours and travel, we customize reliable and trustworthy educational tours to destinations all over the world")
                            .font(bodyFont)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .minimumScaleFactor(0.7) // <-- ADD THIS
                        
                        Spacer()
                            
                        OnboardingPageIndicator(pageCount: 3, currentIndex: 0)
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                            
                        PrimaryButton(title: "Next", action: navigateToOnBoard2)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isOnBoarding2Active) {
                OnBoard2View()
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

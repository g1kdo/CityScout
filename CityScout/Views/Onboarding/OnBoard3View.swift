//
//  OnBoard3View.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct OnBoard3View: View {
    
    @State private var isSignInActive = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                
                // 1. DYNAMIC BACKGROUND: Use systemBackground for the main view
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Image("OnBoard3")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .frame(maxWidth: .infinity)
                            // Assuming RoundedCorner and the extension are available
                            .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
                            .clipped()
                            .ignoresSafeArea(edges: .top)

                        // Skip Button (Needs to be visible against the image, so keep white)
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

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            VStack(spacing: 4) {
                                Text("People don't take trips, trips take")
                                    .font(.system(size: 26, weight: .heavy))
                                    // 2. DYNAMIC TEXT: Use .primary for main text
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text("people")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Color(hex: "#FF7029")) // Brand color remains the same
                                    .multilineTextAlignment(.center)

                                Image("Line")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 10)
                            }
                            .padding(.horizontal, 30.0)

                            Text("To get the best of your adventure you just need to leave and go where you like. We are waiting for you")
                                .font(.system(size: 16))
                                // 3. DYNAMIC SECONDARY TEXT: Use .secondary for descriptive text
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            OnboardingPageIndicator(pageCount: 3, currentIndex: 2)
                                .padding(.top, 10)
                                .padding(.bottom, 16)
                                
                            // The final button navigates to sign in
                            PrimaryButton(title: "Get Started", action: navigateToSignIn)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                        }
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

#Preview {
        OnBoard3View()
}

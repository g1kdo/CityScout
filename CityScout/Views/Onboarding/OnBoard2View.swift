//
//  OnBoard2View.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct OnBoard2View: View {
    
    @State private var isOnBoarding3Active = false
    @State private var isSignInActive = false
    
    var body: some View {
        NavigationStack { // Ensure navigation is properly contained
            ZStack(alignment: .topTrailing) {
                
                // 1. DYNAMIC BACKGROUND: Use systemBackground for the main view
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Image("OnBoard2")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .frame(maxWidth: .infinity)
                            // Assuming RoundedCorner and the extension are available
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
                                .foregroundColor(.white) // Keep white for contrast with image
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .padding(.top, 10.0)
                        .padding(.trailing, 20)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            VStack(spacing: 4) {
                                Text("It's a big world out there go")
                                    .font(.system(size: 26, weight: .heavy))
                                    // 2. DYNAMIC TEXT: Use .primary for main text
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text("explore")
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
                            
                            OnboardingPageIndicator(pageCount: 3, currentIndex: 1) // Assuming this uses dynamic colors internally

                                .padding(.top, 10)
                                .padding(.bottom, 16)
                                
                            PrimaryButton(title: "Next", action: navigateToOnBoard3) // Assuming this uses dynamic colors internally
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isOnBoarding3Active) {
                OnBoard3View()
            }
            .navigationDestination(isPresented: $isSignInActive) {
                SignInView()
            }
        }
    }

    private func navigateToOnBoard3() {
        isOnBoarding3Active = true
    }

    private func navigateToSignIn() {
        isSignInActive = true
    }
}


#Preview {
        OnBoard2View()
}


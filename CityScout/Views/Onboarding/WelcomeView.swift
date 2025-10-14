//
//  WelcomeView.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    @State private var isAnimating: Bool = false
    @State private var shouldNavigate: Bool = false
    
    private let minimumAestheticTime: Double = 1.5 

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#24BAEC")
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1.0 : 0.6)
                        .animation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.2), value: isAnimating)

                    Spacer()

                    Text("City Scout")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                        .padding(.bottom, 30)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: isAnimating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(isPresented: $shouldNavigate) {
                    OnBoard1View()
                }
            }
            .onAppear {
                // startAnimations()
                startLoadingAndAnimationSequence()
            }
        }
        .navigationBarHidden(true)
    }

    private func startAnimations() {
        isAnimating = true
    }
    
    private func startLoadingAndAnimationSequence() {
            // Start the visual animation immediately
            isAnimating = true
            
            Task {
                let startTime = Date()
                
                // --- Phase 1: Resource Loading ---
                // Wait for the AuthenticationViewModel's initial loading to complete
                while authVM.isLoadingInitialData {
                    // Polling frequently to check the loading status
                    try? await Task.sleep(for: .milliseconds(50))
                }
                
                // --- Phase 2: Timing & Navigation ---
                
                // 1. Calculate the time spent loading
                let elapsed = Date().timeIntervalSince(startTime)
                
                // 2. Determine the remaining time needed to meet the minimum aesthetic time.
                let remainingTime = minimumAestheticTime - elapsed
                
                // 3. Wait for the remaining time, if necessary.
                if remainingTime > 0 {
                    // This pause ensures the user sees the animated logo/text for at least 1.5 seconds,
                    // regardless of how fast the loading was.
                    try? await Task.sleep(for: .seconds(remainingTime))
                }
                
                // 4. Navigate after both loading and minimum display time are satisfied.
                shouldNavigate = true
            }
        }
    }

#Preview {
    WelcomeView()
}

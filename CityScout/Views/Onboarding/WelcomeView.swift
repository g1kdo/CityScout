//
//  WelcomeView.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating: Bool = false
    @State private var shouldNavigate: Bool = false

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

                    Spacer()

                    Text("City Scout")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(isPresented: $shouldNavigate) {
                    OnBoard1View()
                }
            }
            .onAppear {
                startAnimations()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    shouldNavigate = true
                }
            }
        }
        .navigationBarHidden(true)
    }

    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0

    private func startAnimations() {
        withAnimation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0.5).delay(0.2)) {
            isAnimating = true
        }
    }
}

#Preview {
    WelcomeView()
}

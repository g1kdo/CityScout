//
//  OnBoard1View.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI

struct OnBoard1View: View {
    
    @State private var isOnBoarding2Active = false
    @State private var isSignUpActive = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

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

                    Button(action: {
                        print("Skip Tapped")
                        navigateToSignUp()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16))
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
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)

                            Text("wide")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundColor(Color(hex: "#FF7029"))
                                .multilineTextAlignment(.center)

                            Image("Line")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 10)
                        }
                        .padding(.horizontal, 30.0)

                        Text("At Friends tours and travel, we customize reliable and trustworthy educational tours to destinations all over the world")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color(hex: "#24BAEC"))
                                .frame(width: 24, height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(Color(hex: "#24BAEC").opacity(0.4))
                                .frame(width: 16, height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(Color(hex: "#24BAEC").opacity(0.2))
                                .frame(width: 8, height: 8)
                                .cornerRadius(4)
                        }
                        .padding(.top, 10)

                        VStack(spacing: 16) {
                            Button(action: {
                                print("Get Started Tapped")
                                navigateToOnBoard2()
                            }) {
                                Text("Get Started")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(hex: "#24BAEC"))
                                    .cornerRadius(10)
                            }

                            Spacer().frame(height: 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
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

    private func navigateToOnBoard2() {
        isOnBoarding2Active = true
    }

    private func navigateToSignIn() {
        isSignInActive = true
    }
}





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

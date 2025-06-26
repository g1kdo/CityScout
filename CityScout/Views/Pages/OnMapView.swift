import SwiftUI

struct OnMapView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - 1. Main Background Image (Full Screen)
                Image("NyandunguMap")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea(.all)

                // MARK: - 2. Dark Overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)

                // MARK: - 3. Top Navigation Bar
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        }
                        label: {
                        Image(systemName: "chevron.left")
                          .foregroundColor(.white)
                          .padding(13)
                          .background(Circle().fill(Color.black.opacity(0.3)))
                      }

                        Spacer()

                        // "View" Title
                        Text("View")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Three Dots Menu Button
                        Button { /* bookmark */ } label: {
                          Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }

                // MARK: - 4. La-Hotel Card with connecting vector
                ZStack {
                    // Card itself
                    HStack(spacing: 12) {
                        Image("Convention")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 50)
                            .cornerRadius(8)
                            .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Raddison Blu")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text("2.09 m")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                    )
                    .frame(width: 180)
                    .position(
                        x: geometry.size.width * 0.75,
                        y: geometry.size.height * 0.25
                    )

                    // → Your vector image (line + dot) just below the card
                    Image("pointer_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        // tweak width/height to match design
                        .frame(width: 120, height: 60)
                        // position so it anchors at the bottom center of the card
                        .position(
                            x: geometry.size.width * 0.75,
                            y: (geometry.size.height * 0.25) + 60// 30 = half card height + some gap
                        )
                }

              
                // MARK: - 5. Lemon Garden Card with connecting vector
                ZStack {
                    // Lemon Garden Card
                    HStack(spacing: 12) {
                        Image("Convention")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 50)
                            .cornerRadius(8)
                            .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lemon Garden")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text("2.09 m")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                    )
                    .frame(width: 180)
                    .position(
                        x: geometry.size.width * 0.35,
                        y: geometry.size.height * 0.55
                    )

                    // Connector vector under Lemon Garden—replace vectorAsset with your asset
                    Image("pointer_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 60)
                        .position(
                            x: geometry.size.width * 0.35,
                            y: (geometry.size.height * 0.55) + 65  // tweak 30 to fit exactly
                        )
                }

                // MARK: - 7. Bottom Information Card
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Rating Row
                        HStack {
                            Text("Nyandungu Eco Park")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 14))
                                
                                Text("4.7")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        // Location and Time Row
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                                
                                Text("Kigali, Nyandungu")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                                
                                Text("45 Minutes")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }

                        // Avatar Row
                        HStack {
                            HStack(spacing: -8) {
                                ForEach(1..<4, id: \.self) { index in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 2)
                                        )
                                        .overlay(
                                            Image("LocalAvatarImage")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 28, height: 28)
                                                .clipShape(Circle())
                                        )
                                }
                                
                                // +50 Circle
                                Circle()
                                    .fill(Color.gray.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                    )
                                    .overlay(
                                        Text("+50")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Spacer()
                        }

                        // See On The Map Button
                        Button(action: {
                            print("See On The Map tapped")
                        }) {
                            Text("See On The Map")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.4, green: 0.8, blue: 1.0),
                                            Color(red: 0.2, green: 0.7, blue: 0.95)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.75))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom,  10)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helper Functions
    private func safeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }

    private func safeAreaBottom() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

// MARK: - Preview
struct ExactReplicaPageView_Previews: PreviewProvider {
    static var previews: some View {
            OnMapView()
    }
}

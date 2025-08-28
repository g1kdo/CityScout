//
//  InterestView.swift
//  CityScout
//
//  Created by Umuco Auca on 14/08/2025.
//

import SwiftUI
import FirebaseFirestore

struct InterestView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var selectedInterests: Set<String> = []
    @State private var isLoading = false
    
    // Define your original interest categories and their new SF Symbols
    let interests: [(name: String, icon: String)] = [
        ("Adventure", "🗺️"),
        ("Beaches", "🌞"),
        ("Mountains", "⛰️"),
        ("City Breaks", "🏙️"), // Changed to a more fitting emoji
        ("Foodie", "🍕"),
        ("Cultural", "🎭"),
        ("Historical", "🕰️"),
        ("Nature", "🌿"),
        ("Relaxing", "💆🏽‍♀️"),
        ("Family", "👨‍👩‍👧‍👦") // Changed to a more fitting emoji
    ]
    
    // Pre-assign a random color to each interest
    @State private var interestColors: [String: Color] = [:]
    
    private var isButtonEnabled: Bool {
        !selectedInterests.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Categories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Select at least one interest to personalize your recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ScrollView(.vertical, showsIndicators: false) {
                    WavyFlowLayout(spacing: 10, waveAmplitude: 15) {
                        ForEach(interests, id: \.name) { interestData in
                            InterestTag(
                                icon: interestData.icon,
                                text: interestData.name,
                                isSelected: selectedInterests.contains(interestData.name),
                                color: interestColors[interestData.name] ?? .gray
                            )
                            .onTapGesture {
                                if selectedInterests.contains(interestData.name) {
                                    selectedInterests.remove(interestData.name)
                                } else {
                                    selectedInterests.insert(interestData.name)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: saveInterests) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#24BAEC"))
                            .cornerRadius(12)
                    } else {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isButtonEnabled ? Color(hex: "#24BAEC") : Color.gray)
                            .cornerRadius(12)
                    }
                }
                .disabled(!isButtonEnabled || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
            .padding(.top)
            .navigationBarHidden(true)
            .onAppear {
                // Assign a random color to each interest when the view appears
                for interest in interests {
                    interestColors[interest.name] = Color.random
                }
            }
        }
    }
    
    private func saveInterests() {
        guard let userId = authVM.user?.uid else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        let initialInterestScores = selectedInterests.reduce(into: [:]) { result, interest in
            result[interest] = 10
        }
        
        userRef.updateData([
            "selectedInterests": Array(selectedInterests),
            "interestScores": initialInterestScores,
            "hasSetInterests": true
        ]) { error in
            self.isLoading = false
            if let error = error {
                print("Error saving interests: \(error.localizedDescription)")
            } else {
                print("Interests saved successfully!")
                Task {
                    await authVM.refreshSignedInUserFromFirestore()
                }
            }
        }
    }
}

// MARK: - Helper Views and Extensions

// MARK: - Helper Views and Extensions

// Custom view for each interest tag (pill-like button)
struct InterestTag: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Check if the icon string is an SF Symbol (contains a dot) or an emoji
            if icon.contains(".") {
                // It's a SF Symbol
                Image(systemName: icon)
                    .font(.title3)
            } else {
                // It's an emoji
                Text(icon)
                    .font(.title3)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(isSelected ? color.opacity(0.2) : Color.white)
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(isSelected ? color : Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

// Wavy Flow Layout
struct WavyFlowLayout: Layout {
    var spacing: CGFloat
    var waveAmplitude: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width + spacing > containerWidth {
                totalHeight += lineHeight + spacing
                currentY = totalHeight
                currentX = 0
                lineHeight = 0
            }
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        totalHeight += lineHeight
        
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        var lineIndex: Int = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if currentX + size.width > containerWidth {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
                lineIndex += 1
            }
            
            // The fix: Add a check for a non-zero containerWidth.
            let yOffset: CGFloat
            if containerWidth > 0 {
                yOffset = sin(CGFloat(lineIndex) + currentX / containerWidth * 2 * .pi) * waveAmplitude
            } else {
                yOffset = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY + yOffset), proposal: ProposedViewSize(size))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

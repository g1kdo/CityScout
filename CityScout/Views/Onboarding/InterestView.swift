//
//  InterestView.swift
//  CityScout
//
//  Created by Umuco Auca on 14/08/2025.
//


import SwiftUI
import FirebaseFirestore

// Main View
struct InterestView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedInterests: Set<String> = []
    @State private var isLoading = false
    
    // Define the original interest categories and their emojis
    let interests: [(name: String, icon: String)] = [
        ("Adventure", "🗺️"),
        ("Beaches", "🌞"),
        ("Mountains", "⛰️"),
        ("City Breaks", "🏙️"),
        ("Foodie", "🍕"),
        ("Cultural", "🎭"),
        ("Historical", "🕰️"),
        ("Nature", "🌿"),
        ("Relaxing", "💆🏽‍♀️"),
        ("Family", "👨‍👩‍👧‍👦")
    ]
    
    @State private var interestColors: [String: Color] = [:]
    
    private let dynamicBackgroundColor: Color = {
            Color(
                UIColor { traitCollection in
                    if traitCollection.userInterfaceStyle == .light {
                        return UIColor(hex: "#FFFFF9") ?? .systemBackground
                    } else {
                        return UIColor(hex: "#1A1A1A") ?? .systemBackground
                    }
                }
            )
        }()
    
    private var isButtonEnabled: Bool {
        !selectedInterests.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Change the background to a system-defined color
//                Color(uiColor: .systemBackground)
//                    .ignoresSafeArea()
                dynamicBackgroundColor
                                   .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Categories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .foregroundColor(Color(uiColor: .label)) // Ensure text is visible
                    
                    Text("Select at least one interest to personalize your recommendations.")
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel)) // Use secondary color for better contrast
                        .padding(.horizontal)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        FlowLayout(spacing: 10) {
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
                                .background(isButtonEnabled ? Color(hex: "#24BAEC") : Color(uiColor: .systemGray2)) // Use systemGray for consistency
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!isButtonEnabled || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .onAppear {
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

struct InterestTag: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 35, height: 35)
                
                if icon.contains(".") {
                    Image(systemName: icon)
                        .font(.title3)
                } else {
                    Text(icon)
                        .font(.title3)
                }
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(isSelected ? color.opacity(0.2) : Color(uiColor: .systemGray6)) // Use a system color for contrast
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(isSelected ? color : Color(uiColor: .systemGray3), lineWidth: 1) // Use systemGray3
        )
    }
}

// Custom FlowLayout to replicate the staggered grid effect (No changes needed)
struct FlowLayout: Layout {
    var spacing: CGFloat
    
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
        var currentLine: [(LayoutSubviews.Element, CGSize)] = []
        var currentLineWidth: CGFloat = 0
        var currentY: CGFloat = bounds.minY
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentLineWidth + size.width > containerWidth && !currentLine.isEmpty {
                placeLine(currentLine, at: currentY, in: bounds, containerWidth: containerWidth)
                currentY += subview.sizeThatFits(.unspecified).height + spacing
                currentLine.removeAll()
                currentLineWidth = 0
            }
            
            currentLine.append((subview, size))
            currentLineWidth += size.width + spacing
            
            if index == subviews.indices.last {
                placeLine(currentLine, at: currentY, in: bounds, containerWidth: containerWidth)
            }
        }
    }
    
    private func placeLine(_ line: [(LayoutSubviews.Element, CGSize)], at y: CGFloat, in bounds: CGRect, containerWidth: CGFloat) {
        let totalLineWidth = line.reduce(0) { $0 + $1.1.width + spacing } - spacing
        let startX = (containerWidth - totalLineWidth) / 2
        var currentX = bounds.minX + startX
        
        for (subview, size) in line {
            subview.place(at: CGPoint(x: currentX, y: y), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}


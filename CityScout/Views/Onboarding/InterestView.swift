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
    
    // Define your interest categories here
    let interests = [
        "Adventure", "Beaches", "Mountains", "City Breaks", "Foodie",
        "Cultural", "Historical", "Nature", "Relaxing", "Family"
    ]
    
    private var isButtonEnabled: Bool {
        !selectedInterests.isEmpty
    }

    var body: some View {
        VStack {
            Text("Tell Us Your Interests")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            Text("Select at least one interest to personalize your recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            ScrollView(.vertical) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(interests, id: \.self) { interest in
                        InterestCard(interest: interest, isSelected: selectedInterests.contains(interest))
                            .onTapGesture {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Button(action: saveInterests) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isButtonEnabled ? Color(hex: "#24BAEC") : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isButtonEnabled)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
            }
        )
    }
    
    // Function to save interests to Firestore
    private func saveInterests() {
        guard let userId = authVM.user?.uid else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        let initialInterestScores = selectedInterests.reduce(into: [:]) { result, interest in
            result[interest] = 10 // Assign a high initial score
        }
        
        userRef.updateData([
            "selectedInterests": Array(selectedInterests),
            "interestScores": initialInterestScores,
            "hasSetInterests": true // Add a flag to prevent this page from showing again
        ]) { error in
            self.isLoading = false
            if let error = error {
                print("Error saving interests: \(error.localizedDescription)")
            } else {
                print("Interests saved successfully!")
                // You might need to refresh the `signedInUser` model
                Task {
                    await authVM.refreshSignedInUserFromFirestore()
                }
            }
        }
    }
}

// Custom view for each interest card
struct InterestCard: View {
    let interest: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: getIconForInterest(interest))
                .font(.largeTitle)
                .frame(width: 60, height: 60)
                .padding()
                .background(isSelected ? Color(hex: "#24BAEC").opacity(0.2) : Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text(interest)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color(hex: "#24BAEC") : .primary)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120)
        .background(isSelected ? Color(hex: "#24BAEC").opacity(0.1) : Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color(hex: "#24BAEC") : Color.gray.opacity(0.2), lineWidth: 2)
        )
    }
    
    private func getIconForInterest(_ interest: String) -> String {
        switch interest {
        case "Adventure": return "car.circle.fill"
        case "Beaches": return "sun.max.fill"
        case "Mountains": return "mountain.2.fill"
        case "City Breaks": return "building.2.fill"
        case "Foodie": return "fork.knife.circle.fill"
        case "Cultural": return "theatermask.and.paintbrush.fill"
        case "Historical": return "clock.fill"
        case "Nature": return "leaf.fill"
        case "Relaxing": return "bed.double.fill"
        case "Family": return "figure.2.and.child.holdinghands"
        default: return "questionmark.circle"
        }
    }
}

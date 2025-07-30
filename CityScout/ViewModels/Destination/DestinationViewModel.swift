//
//  DestinationViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


// ViewModels/DestinationViewModel.swift
import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class DestinationViewModel: ObservableObject {
    @Published var destinations: [Destination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let destinationsCollection = "destinations"

    init() {
        // Automatically start fetching data when the ViewModel is created
        fetchDestinations()
    }

    func fetchDestinations() {
        isLoading = true
        errorMessage = nil
        
        db.collection(destinationsCollection)
            .order(by: "name") // Order by name or a different field if desired
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching destinations: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch destinations."
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found.")
                    self.destinations = []
                    return
                }
                
                // Decode Firestore documents into Destination objects
                self.destinations = documents.compactMap { doc -> Destination? in
                    do {
                        return try doc.data(as: Destination.self)
                    } catch {
                        print("Error decoding destination document: \(error)")
                        return nil
                    }
                }
            }
    }
}
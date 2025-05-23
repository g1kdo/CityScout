import Foundation
import FirebaseFirestore

struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let rating: Double
    let location: String
    let participantAvatars: [String] // these will be local asset names too
    let description: String
   
}




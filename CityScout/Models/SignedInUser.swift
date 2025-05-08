import Foundation

struct SignedInUser: Identifiable {
  let id: String           // Firebase UID
  let displayName: String  // Full name
  let email: String
}


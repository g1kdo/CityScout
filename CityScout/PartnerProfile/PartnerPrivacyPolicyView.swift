import SwiftUI

struct PartnerPrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.largeTitle).bold()
                    .padding(.bottom)

                Text("Last updated: August 7, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                Text("1. Information We Collect")
                    .font(.title2).bold()
                Text("We collect information you provide directly to us, such as when you create an account, update your profile, post reviews, or otherwise communicate with us. This information may include your name, email address, phone number, profile picture, and location.")
                    .padding(.bottom)

                Text("2. How We Use Your Information")
                    .font(.title2).bold()
                Text("We use the information we collect to operate, maintain, and provide you with the features and functionality of the CityScout app, as well as to communicate with you, such as to send you service-related emails or messages.")
                    .padding(.bottom)
                
                Text("3. Sharing of Your Information")
                    .font(.title2).bold()
                Text("We do not rent or sell your personal information to third parties outside CityScout without your consent, except as noted in this Policy.")
                    .padding(.bottom)
                
                // Add more sections as needed...
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

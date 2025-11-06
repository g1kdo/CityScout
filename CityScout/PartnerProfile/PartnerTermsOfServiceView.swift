import SwiftUI

struct PartnerTermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.largeTitle).bold()
                    .padding(.bottom)

                Text("Last updated: August 7, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                Text("1. Acceptance of Terms")
                    .font(.title2).bold()
                Text("By accessing or using the CityScout application, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, then you do not have permission to access the Service.")
                    .padding(.bottom)

                Text("2. User Content")
                    .font(.title2).bold()
                Text("Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, or other material ('Content'). You are responsible for the Content that you post on or through the Service, including its legality, reliability, and appropriateness.")
                    .padding(.bottom)
                
                Text("3. Accounts")
                    .font(.title2).bold()
                Text("When you create an account with us, you guarantee that you are above the age of 18, and that the information you provide us is accurate, complete, and current at all times. Inaccurate, incomplete, or obsolete information may result in the immediate termination of your account on the Service.")
                    .padding(.bottom)
                
                // Add more sections as needed...
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}



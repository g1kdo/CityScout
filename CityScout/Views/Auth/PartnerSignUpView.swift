import SwiftUI
import FirebaseAuth
import AuthenticationServices
import PhotosUI // Added for image selection
import Kingfisher // Added for potential display (though initial sign up won-t have a URL)

// Note: Ensure your PartnerAuthenticationViewModel has the image properties defined below.
struct PartnerSignUpView: View {
    // Inject the Partner-specific ViewModel as an EnvironmentObject
    @EnvironmentObject var partnerAuthVM: PartnerAuthenticationViewModel 
    
    // Local state for UI
    @State private var isAgreed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerSection
                profilePictureSection // NEW: Profile Picture selection integrated here
                fieldsSection 
                termsSection
                activationButton
                footerSection
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
        .alert(partnerAuthVM.errorMessage.isEmpty ? partnerAuthVM.successMessage : partnerAuthVM.errorMessage, 
               isPresented: $partnerAuthVM.showAlert) {
            Button("OK", role: .cancel) {
                partnerAuthVM.errorMessage = ""
                partnerAuthVM.successMessage = ""
            }
        }
        // Navigation is updated to PartnerMessagesView
        .fullScreenCover(isPresented: $partnerAuthVM.isAuthenticated) {
            PartnerMessagesView() 
                .environmentObject(partnerAuthVM)
        }
    }

    // ─── Sections ────────────────────────────────────────────

    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("Partner Account Activation")
                .font(.title.bold())
                .padding(.top, 15)

            Text("Please complete your profile details to activate your account.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 15)
        }
    }

    // NEW: Profile Picture Section
    private var profilePictureSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) { 
                // Display the selected image or the default placeholder
                if let image = partnerAuthVM.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else {
                    // Default placeholder icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }

                // PhotosPicker button (the "pen" icon)
                PhotosPicker(selection: $partnerAuthVM.selectedPhotoItem, matching: .images) {
                    Image(systemName: "pencil.circle.fill") // Pen icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color.white)
                        .background(Color.black)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1)) 
                }
                .offset(x: 5, y: 5) 
            }
            
            Text("Set Profile Picture (Optional)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .onChange(of: partnerAuthVM.selectedPhotoItem) { _, newItem in
            // Trigger image loading in the ViewModel when an item is selected
            if let newItem = newItem {
                partnerAuthVM.loadImage(from: newItem)
            }
        }
    }

    private var fieldsSection: some View {
        Group {
            // 1. Email (Used for lookup/validation)
            FloatingField(
                label: "Registered Partner Email",
                placeholder: "Enter the email your account was registered with",
                text: $partnerAuthVM.email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .disabled(partnerAuthVM.isAuthenticating) 
            
            // 2. Full Name
            FloatingField(
                label: "Full Name",
                placeholder: "Enter your full name",
                text: $partnerAuthVM.partnerDisplayName
            )
            
            // 3. Phone Number
            FloatingField(
                label: "Phone Number",
                placeholder: "Enter your contact number",
                text: $partnerAuthVM.phoneNumber,
                keyboardType: .phonePad
            )
            
            // 4. Location
            FloatingField(
                label: "Location / Address",
                placeholder: "Enter your business location",
                text: $partnerAuthVM.location
            )
        }
    }

    private var termsSection: some View {
        HStack(alignment: .top) {
            Button { isAgreed.toggle() } label: {
                Image(systemName: isAgreed
                    ? "checkmark.square.fill"
                    : "square")
                    .font(.title3)
                    .foregroundColor(
                        isAgreed
                            ? Color(hex: "#24BAEC")
                            : .secondary
                    )
            }

            Text("I agree with the ")
            Text("Terms of Service")
                .foregroundColor(Color(hex: "#FF7029"))
                .onTapGesture { openURL("https://your.app/terms") }
            Text(" and ")
            Text("Privacy Policy")
                .foregroundColor(Color(hex: "#FF7029"))
                .onTapGesture { openURL("https://your.app/privacy") }
        }
        .font(.footnote)
    }

    private var activationButton: some View {
        Button {
            Task {
                if !isAgreed {
                    partnerAuthVM.errorMessage = "You must agree to the Terms and Privacy Policy."
                    partnerAuthVM.showAlert = true
                } else {
                    await partnerAuthVM.completeProfileAndActivate()
                }
            }
        } label: {
            Group {
                if partnerAuthVM.isAuthenticating {
                    ProgressView()
                } else {
                    Text("Activate Account")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(
            !isAgreed ||
            partnerAuthVM.email.isEmpty ||
            partnerAuthVM.partnerDisplayName.isEmpty ||
            partnerAuthVM.phoneNumber.isEmpty ||
            partnerAuthVM.location.isEmpty ||
            partnerAuthVM.isAuthenticating
        )
        .opacity(
            (!isAgreed || partnerAuthVM.email.isEmpty || partnerAuthVM.partnerDisplayName.isEmpty || partnerAuthVM.phoneNumber.isEmpty || partnerAuthVM.location.isEmpty)
            ? 0.6 : 1.0
        )
    }

    private var footerSection: some View {
        HStack {
            Text("Trouble activating your account?")
                .foregroundColor(.gray)
                .font(.footnote)
            Button("Contact Support") {
                // Action to contact support (e.g., mailto: link)
            }
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "#FF7029"))
            .font(.footnote)
        }
        .padding(.bottom, 20)
    }

    private func openURL(_ str: String) {
        guard let url = URL(string: str) else { return }
        UIApplication.shared.open(url)
    }
}

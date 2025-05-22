// ViewModels/ProfileViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage // For profile picture uploads (optional for now)
import Combine
import PhotosUI // For image picking

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var signedInUser: SignedInUser
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var location: String = ""
    @Published var mobileNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingImagePicker: Bool = false
    @Published var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            Task {
                await loadSelectedImage()
            }
        }
    }
    @Published var profileImage: UIImage? // The image to display/upload

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init(user: SignedInUser) {
        self.signedInUser = user
        // Initialize editable fields with current user data
        _firstName = Published(initialValue: user.firstName ?? "")
        _lastName = Published(initialValue: user.lastName ?? "")
        _location = Published(initialValue: user.location ?? "")
        _mobileNumber = Published(initialValue: user.mobileNumber ?? "")

        // Observe changes to signedInUser to update local fields
        $signedInUser
            .sink { [weak self] user in
                self?.firstName = user.firstName ?? ""
                self?.lastName = user.lastName ?? ""
                self?.location = user.location ?? ""
                self?.mobileNumber = user.mobileNumber ?? ""
                // Potentially load profile image from URL if available
                if let url = user.profilePictureURL {
                    self?.loadImageFromURL(url)
                }
            }
            .store(in: &cancellables)

        // Fetch additional profile data from Firestore
        fetchProfileData()
    }

    func fetchProfileData() {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to fetch profile data for."
            return
        }

        isLoading = true
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                // Create a temporary SignedInUser to update from Firestore data
                var updatedUser = self.signedInUser
                updatedUser.updateWithProfileData(data)
                self.signedInUser = updatedUser // This will trigger the sink and update @Published properties

                // Also update the local image if a URL is found in Firestore
                if let photoURLString = data["profilePictureURL"] as? String, let url = URL(string: photoURLString) {
                    self.loadImageFromURL(url)
                }

            } else if let error = error {
                self.errorMessage = "Error fetching profile data: \(error.localizedDescription)"
                print("Error fetching profile data: \(error.localizedDescription)")
            } else {
                self.errorMessage = "Profile data not found. It might be a new user or not yet saved."
                print("Profile data not found in Firestore for user: \(firebaseUser.uid)")
            }
        }
    }

    func updateProfile() async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to update profile for."
            return false
        }

        isLoading = true
        errorMessage = ""

        var updatedFields: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "location": location,
            "mobileNumber": mobileNumber
        ]

        do {
            // Update Firebase Auth display name if first name is available and different
            if firebaseUser.displayName != "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines) {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                try await changeRequest.commitChanges()
                print("Firebase Auth display name updated.")
            }

            // Upload profile image if it exists and has changed
            if let image = profileImage {
                if let url = await uploadProfileImage(image, forUser: firebaseUser.uid) {
                    updatedFields["profilePictureURL"] = url.absoluteString
                    // Update Firebase Auth photoURL as well
                    if firebaseUser.photoURL?.absoluteString != url.absoluteString {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.photoURL = url
                        try await changeRequest.commitChanges()
                        print("Firebase Auth photo URL updated.")
                    }
                } else {
                    errorMessage = "Failed to upload profile picture."
                    isLoading = false
                    return false
                }
            }


            // Update custom profile data in Firestore
            try await db.collection("users").document(firebaseUser.uid).setData(updatedFields, merge: true)

            // Update the local signedInUser object
            var tempUser = self.signedInUser
            tempUser.displayName = firebaseUser.displayName // Get updated display name from Firebase Auth
            tempUser.firstName = self.firstName
            tempUser.lastName = self.lastName
            tempUser.location = self.location
            tempUser.mobileNumber = self.mobileNumber
            tempUser.profilePictureURL = firebaseUser.photoURL // Get updated photo URL from Firebase Auth
            self.signedInUser = tempUser // This will update the UI via the sink

            print("Profile updated successfully in Firestore and Firebase Auth.")
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            print("Error updating profile: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    // MARK: - Image Handling

    private func loadImageFromURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            } else {
                print("Error loading image from URL: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }

    private func loadSelectedImage() async {
        guard let selectedItem = selectedPhotoItem else { return }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        } catch {
            errorMessage = "Failed to load selected image: \(error.localizedDescription)"
            print("Error loading selected image: \(error.localizedDescription)")
        }
    }

    private func uploadProfileImage(_ image: UIImage, forUser uid: String) async -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to convert image to data."
            return nil
        }

        let storageRef = Storage.storage().reference().child("profile_pictures").child("\(uid).jpg")

        do {
            let _ = try await storageRef.putDataAsync(imageData)
            let downloadURL = try await storageRef.downloadURL()
            print("Profile image uploaded successfully: \(downloadURL.absoluteString)")
            return downloadURL
        } catch {
            errorMessage = "Error uploading profile image: \(error.localizedDescription)"
            print("Error uploading profile image: \(error.localizedDescription)")
            return nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // Attempt to sign out from social providers if they are logged in
            GIDSignIn.sharedInstance.signOut() // Google Sign-In
            LoginManager().logOut() // Facebook Sign-In

            // Reset current user and other state
            self.signedInUser = SignedInUser(id: "", displayName: nil, email: "") // Reset to a dummy user or handle nil
            self.firstName = ""
            self.lastName = ""
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.errorMessage = ""

            print("User signed out successfully from Firebase and social providers.")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
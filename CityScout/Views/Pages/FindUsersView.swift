//
//  FindUsersView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher
import Combine

struct FindUsersView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var viewModel = MessageViewModel()
    @EnvironmentObject var homeVM: HomeViewModel
    @State private var cancellables = Set<AnyCancellable>()

    let onUserSelected: (SignedInUser) -> Void
    @State private var searchText: String = ""
    
    // FIX: Filter the recommended users list instead of all users.
    var filteredUsers: [SignedInUser] {
        if searchText.isEmpty {
            return viewModel.recommendedUsers
        } else {
            return viewModel.recommendedUsers.filter { user in
                user.displayName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 15) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .background(Circle().fill(Color(.systemGray6)).frame(width: 40, height: 40))
                    }
                    Spacer()

                    Text("New Message")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                

                SearchBarView(searchText: $searchText, placeholder: "Search recommended users", isMicrophoneActive: homeVM.isListeningToSpeech) {
                    // Action on search tapped
                } onMicrophoneTapped: {
                    homeVM.handleMicrophoneTapped()
                }
                
                ScrollView {
                    LazyVStack {
                        if viewModel.isLoading {
                            ProgressView("Finding users...")
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else if filteredUsers.isEmpty && !searchText.isEmpty {
                            Text("No users found for \"\(searchText)\"")
                                .foregroundColor(.secondary)
                                .padding()
                        } else if filteredUsers.isEmpty {
                             Text("No users recommended based on your interests.")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            // NEW: Section for Recommended Users
                            Section(header: Text("Recommended Users").font(.subheadline).foregroundColor(.secondary).padding(.leading)) {
                                ForEach(filteredUsers) { user in
                                    UserRow(user: user)
                                        .onTapGesture {
                                            onUserSelected(user)
                                        }
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    // FIX: Call the new function to fetch recommended users
                    await viewModel.fetchRecommendedUsers()
                }
                homeVM.$transcribedText
                            .dropFirst() // Don't use the initial value
                            .filter { _ in self.homeVM.isListeningToSpeech == false } // Only act after listening stops
                            .sink { newText in // No capture list needed for struct
                                guard !newText.isEmpty else { return }
                                
                                self.searchText = newText
                                self.homeVM.transcribedText = ""
                            }
                            .store(in: &cancellables)
            }
            .onDisappear {
                cancellables.removeAll()
            }
        }
    }
}

private struct UserRow: View {
    let user: SignedInUser
    
    var body: some View {
        HStack(spacing: 15) {
            KFImage(user.profilePictureAsURL)
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user.displayName ?? "User")
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

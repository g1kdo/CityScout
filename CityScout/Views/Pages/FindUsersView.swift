//
//  FindUsersView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher

struct FindUsersView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var viewModel = MessageViewModel()

    let onUserSelected: (SignedInUser) -> Void
    @State private var searchText: String = ""
    
    var filteredUsers: [SignedInUser] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { user in
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
                    }

                    Text("New Message")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                
                SearchBarView(searchText: $searchText, placeholder: "Search for users")
                
                ScrollView {
                    LazyVStack {
                        if viewModel.isLoading {
                            ProgressView("Loading users...")
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
                             Text("No other users found.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(filteredUsers) { user in
                                UserRow(user: user)
                                    .onTapGesture {
                                        onUserSelected(user)
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
                    await viewModel.fetchUsers()
                }
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


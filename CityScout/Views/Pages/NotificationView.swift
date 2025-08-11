//
//  NotificationView.swift
//  CityScout
//
//  Created by Umuco Auca on 07/08/2025.
//


import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var viewModel: NotificationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: Tab = .recent
    @State private var showActionSheet = false
    @State private var selectedNotification: Notification?
    
    enum Tab: String, CaseIterable {
        case recent = "Recent"
        case earlier = "Earlier"
        case archived = "Archived"
    }
    
    // Custom date formatter for displaying time and date
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E,h:mma"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
                }
                .foregroundColor(.black)
                
                Spacer()
                
                Text("Notification")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                }) {
                    Text("Mark as Read")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Tab Selector
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .bold : .regular)
                                .foregroundColor(selectedTab == tab ? .black : .gray)
                            
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == tab ? .orange : .clear)
                        }
                    }
                }
            }
            .padding(.top, 10)
            
            Divider()
            
            // Notification List
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if filteredNotifications.isEmpty {
                                Text("No notifications found.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(filteredNotifications) { notification in
                                    NotificationRow(notification: notification, selectedTab: selectedTab)
                                        .onTapGesture {
                                            if !notification.isRead {
                                                Task {
                                                    await viewModel.markAsRead(notification)
                                                }
                                            }
                                        }
                                        .onLongPressGesture {
                                            selectedNotification = notification
                                            showActionSheet = true
                                        }
                                    
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Notification Options"),
                buttons: [
                    .default(Text(selectedTab == .archived ? "Unarchive" : "Archive")) {
                        if let notification = selectedNotification {
                            Task {
                                if selectedTab == .archived {
                                    await viewModel.unarchiveNotification(notification)
                                } else {
                                    await viewModel.archiveNotification(notification)
                                }
                            }
                        }
                    },
                    .destructive(Text("Delete")) {
                        if let notification = selectedNotification {
                            Task {
                                await viewModel.deleteNotification(notification)
                            }
                        }
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            viewModel.fetchNotifications()
        }
    }
    
    // Helper to filter notifications based on the selected tab
    private var filteredNotifications: [Notification] {
        switch selectedTab {
        case .recent:
            return viewModel.recentNotifications
        case .earlier:
            return viewModel.earlierNotifications
        case .archived:
            return viewModel.archivedNotifications
        }
    }
}

// Replicating the row design from the image
struct NotificationRow: View {
    let notification: Notification
    let selectedTab: NotificationView.Tab
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Placeholder for the user's profile image
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))) // Random color for demonstration
                .overlay(Text("😎").font(.title))
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(NotificationView.timeFormatter.string(from: notification.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(notification.isRead || selectedTab != .recent ? Color.white : Color.gray.opacity(0.1))
    }
}

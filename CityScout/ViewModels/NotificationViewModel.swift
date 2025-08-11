//
//  NotificationViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/08/2025.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var recentNotifications: [Notification] = []
    @Published var earlierNotifications: [Notification] = []
    @Published var archivedNotifications: [Notification] = []
    @Published var unreadCount: Int = 0 // New property for unread count
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        fetchNotifications()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("users").document(userId).collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch notifications: \(error.localizedDescription)"
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No notifications found.")
                    self.recentNotifications = []
                    self.earlierNotifications = []
                    self.archivedNotifications = []
                    self.unreadCount = 0 // Set to 0 if no notifications
                    return
                }
                
                let allNotifications: [Notification] = documents.compactMap { doc in
                    try? doc.data(as: Notification.self)
                }
                
                self.recentNotifications = allNotifications.filter { !$0.isRead && !$0.isArchived }
                self.earlierNotifications = allNotifications.filter { $0.isRead && !$0.isArchived }
                self.archivedNotifications = allNotifications.filter { $0.isArchived }
                
                // Update the unread count based on the number of unread notifications
                self.unreadCount = self.recentNotifications.count
            }
    }
    
    
    func markAllAsRead() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Combine all unread notifications from recent and earlier tabs
        let allUnreadNotifications = recentNotifications.filter { !$0.isRead }
        
        let batch = db.batch()
        
        for notification in allUnreadNotifications {
            guard let id = notification.id else { continue }
            let docRef = db.collection("users").document(userId).collection("notifications").document(id)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        do {
            try await batch.commit()
            print("Successfully marked all notifications as read.")
        } catch {
            self.errorMessage = "Failed to mark all notifications as read: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
    
    func markAsRead(_ notification: Notification) async {
        guard let userId = Auth.auth().currentUser?.uid, let id = notification.id else { return }
        
        do {
            try await db.collection("users").document(userId).collection("notifications").document(id).updateData([
                "isRead": true
            ])
            print("Notification \(id) marked as read.")
        } catch {
            self.errorMessage = "Failed to mark notification as read: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
    
    func archiveNotification(_ notification: Notification) async {
        guard let userId = Auth.auth().currentUser?.uid, let id = notification.id else { return }
        
        do {
            try await db.collection("users").document(userId).collection("notifications").document(id).updateData([
                "isArchived": true
            ])
            print("Notification \(id) archived.")
        } catch {
            self.errorMessage = "Failed to archive notification: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
    
    func unarchiveNotification(_ notification: Notification) async {
        guard let userId = Auth.auth().currentUser?.uid, let id = notification.id else { return }
        
        do {
            try await db.collection("users").document(userId).collection("notifications").document(id).updateData([
                "isArchived": false
            ])
            print("Notification \(id) unarchived.")
        } catch {
            self.errorMessage = "Failed to unarchive notification: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
    
    func deleteNotification(_ notification: Notification) async {
        guard let userId = Auth.auth().currentUser?.uid, let id = notification.id else { return }
        
        do {
            try await db.collection("users").document(userId).collection("notifications").document(id).delete()
            print("Notification \(id) deleted.")
        } catch {
            self.errorMessage = "Failed to delete notification: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
}

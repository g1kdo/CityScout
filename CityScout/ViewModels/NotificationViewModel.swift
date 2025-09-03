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
    @Published var archivedNotifications: [Notification] = []
    @Published var unreadCount: Int = 0
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        Task {
            await self.cleanUpOldNotifications()
            self.fetchNotifications()
        }
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
                    self.archivedNotifications = []
                    self.unreadCount = 0
                    return
                }
                
                let allNotifications: [Notification] = documents.compactMap { doc in
                    try? doc.data(as: Notification.self)
                }
                
                // Separate notifications into recent and archived
                let now = Date()
                let threeDaysAgo = Calendar.current.date(byAdding: .hour, value: -72, to: now)!
                
                self.recentNotifications = allNotifications.filter {
                    !$0.isArchived && $0.timestamp >= threeDaysAgo
                }
                
                self.archivedNotifications = allNotifications.filter { $0.isArchived }
                
                // Update the unread count based on recent and unread notifications
                self.unreadCount = self.recentNotifications.filter { !$0.isRead }.count
            }
    }
    
    func markAllAsRead() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Mark both recent and archived notifications as read if they're unread
        let allUnreadNotifications = (recentNotifications + archivedNotifications).filter { !$0.isRead }
        
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
    
    func cleanUpOldNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let threeDaysAgo = Calendar.current.date(byAdding: .hour, value: -72, to: Date())!
        
        do {
            let querySnapshot = try await db.collection("users").document(userId).collection("notifications")
                .whereField("isArchived", isEqualTo: false)
                .whereField("timestamp", isLessThan: threeDaysAgo)
                .getDocuments()
            
            guard !querySnapshot.documents.isEmpty else {
                print("No old, unarchived notifications to delete.")
                return
            }
            
            let batch = db.batch()
            for document in querySnapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
            print("Successfully deleted \(querySnapshot.documents.count) old notifications.")
        } catch {
            self.errorMessage = "Failed to clean up old notifications: \(error.localizedDescription)"
            print(self.errorMessage)
        }
    }
}

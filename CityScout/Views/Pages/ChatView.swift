//
//  ChatView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher
import AVFoundation
import PhotosUI // Added the missing import for PhotosUI

struct ChatView: View {
    // FIX: The chat object must be passed into the view.
    let chat: Chat
    
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var messageText: String = ""
    
    // NEW: State for image selection and voice recording
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingVoiceRecorder = false
    @State private var isShowingReportSheet = false
    
    @State private var reportReason: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header for the chat view.
            HStack(spacing: 15) {
                // FIX: Added a back button that uses the dismiss environment object
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // NEW: Partner's profile picture and name
                KFImage(chat.partnerProfilePictureURL)
                    .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    // FIX: Safely unwrap the display name
                    Text(chat.partnerDisplayName ?? "Unknown User")
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let userId = authVM.signedInUser?.id, let muted = chat.mutedBy?[userId], muted {
                        Text("Conversation Muted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let partnerId = chat.partnerId, viewModel.typingStatus.contains(partnerId) {
                        Text("Typing...")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        // Display the partner's status, e.g., "Online" or "Offline"
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()

                Menu {
                    Button(action: {
                        Task {
                            if let userId = authVM.signedInUser?.id, let chatId = chat.id {
                                await viewModel.muteChat(chatId: chatId, forUser: userId)
                            }
                        }
                    }) {
                        Text("Mute Conversation")
                    }
                    Button("Report User", role: .destructive, action: { isShowingReportSheet = true })
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .sheet(isPresented: $isShowingReportSheet) {
                ReportUserSheet(reportReason: $reportReason) { reason in
                    Task {
                        if let chatId = chat.id {
                            // FIX: Safely unwrap the partnerId
                            if let recipientId = chat.partnerId {
                                await viewModel.reportUser(chatId: chatId, recipientId: recipientId, reason: reason)
                            }
                        }
                    }
                }
            }

            // Message List.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageRow(
                                message: message,
                                isFromCurrentUser: message.senderId == authVM.signedInUser?.id,
                                // Pass partner info directly for efficiency
                                partnerDisplayName: chat.partnerDisplayName,
                                partnerProfilePictureURL: chat.partnerProfilePictureURL
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _, newMessages in
                    if let lastMessageId = newMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input Field.
            MessageInputView(
                messageText: $messageText,
                onSend: {
                    if !messageText.isEmpty {
                        if let chatId = chat.id {
                            Task {
                                // FIX: Safely unwrap the partnerId
                                if let recipientId = chat.partnerId {
                                    await viewModel.sendMessage(chatId: chatId, text: messageText, recipientId: recipientId)
                                    messageText = ""
                                }
                            }
                        }
                    }
                },
                onImageSelected: { image in
                    // Handle image sending logic here
                    if let chatId = chat.id {
                        Task {
                             if let recipientId = chat.partnerId {
                                await viewModel.uploadImageAndSendMessage(chatId: chatId, image: image, recipientId: recipientId)
                             }
                        }
                    }
                },
                isRecording: $viewModel.isRecording,
                onStartRecording: {
                    viewModel.startRecording()
                },
                onStopRecording: {
                    if let audioUrl = viewModel.stopRecording() {
                        if let chatId = chat.id {
                             if let recipientId = chat.partnerId {
                                Task { await viewModel.uploadVoiceNoteAndSendMessage(chatId: chatId, audioUrl: audioUrl, recipientId: recipientId) }
                            }
                        }
                    }
                }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            if let chatId = chat.id {
                viewModel.subscribeToMessages(chatId: chatId)
            }
        }
        .onDisappear {
            viewModel.messagesListener?.remove()
        }
    }
}

// A view for a single message.
private struct MessageRow: View {
    let message: Message
    let isFromCurrentUser: Bool
    // NEW: Partner info is passed in directly to avoid lookups
    let partnerDisplayName: String?
    let partnerProfilePictureURL: URL?

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if isFromCurrentUser {
                Spacer()
                messageContent
            } else {
                partnerAvatar
                messageContent
                Spacer()
            }
        }
    }
    
    private var partnerAvatar: some View {
        KFImage(partnerProfilePictureURL)
            .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
            .resizable()
            .scaledToFill()
            .frame(width: 35, height: 35)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // NEW: Handle different message types
            switch message.messageType {
            case .text:
                if let text = message.text {
                    Text(text)
                        .padding(12)
                        .background(isFromCurrentUser ? Color(hex: "#24BAEC") : Color(.systemGray6))
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .cornerRadius(15, corners: isFromCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                }
            case .image:
                if let imageUrl = message.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250)
                        .cornerRadius(15)
                }
            case .voice:
                if let audioUrl = message.audioUrl {
                    // Placeholder for a voice note player
                    VoiceNotePlayerView(audioUrl: audioUrl, isFromCurrentUser: isFromCurrentUser)
                }
            }
            
            Text(formattedTime(from: message.timestamp.dateValue()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// The text input field and send button.
private struct MessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onImageSelected: (UIImage) -> Void
    @Binding var isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    @State private var showingImagePicker = false
    // Fix: Declaring the correct type `PhotosPickerItem?`
    @State private var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            if let selectedPhotoItem {
                Task {
                    if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
    
    // NEW: This is the view that contains the text field and buttons
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Image picker button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color(hex: "#24BAEC"))
                }
                
                // Voice recorder button
                VoiceRecorderButton(isRecording: $isRecording, onStart: onStartRecording, onStop: onStopRecording)
                
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(messageText.isEmpty ? .secondary : Color(hex: "#24BAEC"))
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        }
    }
}

// NEW: Voice Note Player View
struct VoiceNotePlayerView: View {
    let audioUrl: String
    let isFromCurrentUser: Bool
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            if isPlaying {
                audioPlayer?.pause()
            } else {
                playAudio()
            }
        }) {
            HStack {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                
                Text("Voice Note")
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
            }
            .padding(12)
            .background(isFromCurrentUser ? Color(hex: "#24BAEC") : Color(.systemGray6))
            .cornerRadius(15)
        }
        .onAppear {
            prepareAudioPlayer()
        }
    }
    
    private func prepareAudioPlayer() {
        guard let url = URL(string: audioUrl) else { return }
        
        // This is a simplified approach. In a real app, you would
        // download the audio file to a temporary location first.
        do {
            let data = try Data(contentsOf: url)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = nil // You might want to implement a delegate for playback completion
        } catch {
            print("Error preparing audio player: \(error.localizedDescription)")
        }
    }
    
    private func playAudio() {
        audioPlayer?.play()
        isPlaying = true
    }
}

// NEW: Voice Recorder Button
struct VoiceRecorderButton: View {
    @Binding var isRecording: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        Button(action: {
            if isRecording {
                onStop()
            } else {
                onStart()
            }
        }) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(isRecording ? .red : Color(hex: "#FF7029"))
        }
    }
}

// NEW: Report User Sheet
struct ReportUserSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reportReason: String
    let onReport: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Reason for Reporting")) {
                    TextEditor(text: $reportReason)
                        .frame(height: 150)
                }
                
                Button("Submit Report") {
                    onReport(reportReason)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray3))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .navigationTitle("Report User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

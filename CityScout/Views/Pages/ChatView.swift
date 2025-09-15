//
//  ChatView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher
import AVFoundation
import PhotosUI

struct ChatView: View {
    let chat: Chat
    
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var messageText: String = ""
    @State private var isShowingReportSheet = false
    @State private var alertMessage: String = ""
    @State private var showingAlert = false
    @State private var reportReason: String = ""
    
    // Use a dedicated state variable for the PhotosPicker item
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    private var isMuted: Bool {
        guard let userId = authVM.signedInUser?.id, let muted = chat.mutedBy?[userId] else { return false }
        return muted
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            messageListView
            messageInputView
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
        .alert("Error", isPresented: $showingAlert, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .onChange(of: viewModel.errorMessage) { _, newMessage in
            if newMessage != nil {
                self.showingAlert = true
            }
        }
    }
    
    // MARK: - Sub-views for better modularity
    
    private var headerView: some View {
        HStack(spacing: 15) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            KFImage(chat.partnerProfilePictureURL)
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(chat.partnerDisplayName ?? "Unknown User")
                    .font(.headline)
                    .lineLimit(1)
                
                if isMuted {
                    Text("Conversation Muted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let partnerId = chat.partnerId, viewModel.typingStatus.contains(partnerId) {
                    Text("Typing...")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
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
                            if isMuted {
                                await viewModel.unmuteChat(chatId: chatId, forUser: userId)
                            } else {
                                await viewModel.muteChat(chatId: chatId, forUser: userId)
                            }
                        }
                    }
                }) {
                    Text(isMuted ? "Unmute Conversation" : "Mute Conversation")
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
                    if let chatId = chat.id, let recipientId = chat.partnerId {
                        await viewModel.reportUser(chatId: chatId, recipientId: recipientId, reason: reason)
                    }
                }
            }
        }
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.canLoadMoreMessages {
                        ProgressView()
                            .onAppear {
                                if let chatId = chat.id {
                                    viewModel.loadMoreMessages(chatId: chatId)
                                }
                            }
                    }
                    
                    ForEach(viewModel.messages) { message in
                        MessageRow(
                            message: message,
                            isFromCurrentUser: message.senderId == authVM.signedInUser?.id,
                            partnerDisplayName: chat.partnerDisplayName,
                            partnerProfilePictureURL: chat.partnerProfilePictureURL,
                            onLongPress: {
                                if let currentUserId = authVM.signedInUser?.id, message.senderId == currentUserId {
                                    Task {
                                        if let chatId = chat.id {
                                            await viewModel.deleteMessage(chatId: chatId, messageId: message.id!)
                                        }
                                    }
                                    HapticManager.shared.play(feedback: .medium)
                                }
                            }
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
    }
    
    private var messageInputView: some View {
        MessageInputView(
            messageText: $messageText,
            onSend: {
                if !messageText.isEmpty {
                    if let chatId = chat.id, let recipientId = chat.partnerId {
                        Task {
                            await viewModel.sendMessage(chatId: chatId, text: messageText, recipientId: recipientId)
                            HapticManager.shared.play(feedback: .light)
                            messageText = ""
                        }
                    }
                }
            },
            selectedPhotoItem: $selectedPhotoItem,
            onImageSelected: { image in
                if let chatId = chat.id, let recipientId = chat.partnerId {
                    Task {
                        await viewModel.uploadImageAndSendMessage(chatId: chatId, image: image, recipientId: recipientId)
                        HapticManager.shared.play(feedback: .light)
                    }
                }
            },
            isRecording: $viewModel.isRecording,
            onStartRecording: {
                viewModel.startRecording()
                HapticManager.shared.play(feedback: .light)
            },
            onStopRecording: {
                if let audioUrl = viewModel.stopRecording() {
                    if let chatId = chat.id, let recipientId = chat.partnerId {
                        Task {
                            await viewModel.uploadVoiceNoteAndSendMessage(chatId: chatId, audioUrl: audioUrl, recipientId: recipientId)
                            HapticManager.shared.play(feedback: .light)
                        }
                    }
                }
            }
        )
    }
}

// A view for a single message.
private struct MessageRow: View {
    let message: Message
    let isFromCurrentUser: Bool
    let partnerDisplayName: String?
    let partnerProfilePictureURL: URL?
    let onLongPress: () -> Void

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
        .onLongPressGesture {
            onLongPress()
            HapticManager.shared.play(feedback: .medium)
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
    
    // Pass the PhotosPickerItem binding and onImageSelected closure
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void
    
    @Binding var isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color(hex: "#24BAEC"))
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    if let newItem = newItem {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                if let image = UIImage(data: data) {
                                    onImageSelected(image)
                                }
                            }
                        }
                    }
                }

                VoiceRecorderButton(isRecording: $isRecording, onStart: onStartRecording, onStop: onStopRecording)
                
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
                
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

// This class will handle all audio playback logic.
private class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func startPlayback(audioData: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            self.duration = audioPlayer?.duration ?? 0
            self.isPlaying = true
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        self.isPlaying = false
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        self.isPlaying = false
        self.timer?.invalidate()
        self.timer = nil
        self.currentTime = 0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stopPlayback()
    }
}

// Voice Note Player View as a struct, using the new manager.
private struct VoiceNotePlayerView: View {
    let audioUrl: String
    let isFromCurrentUser: Bool
    
    @State private var audioData: Data?
    @State private var isDownloading = false
    @StateObject private var audioManager = AudioPlayerManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isDownloading {
                ProgressView("Downloading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    if audioManager.isPlaying {
                        audioManager.pausePlayback()
                    } else if let data = audioData {
                        audioManager.startPlayback(audioData: data)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(isFromCurrentUser ? .white : .primary)
                        
                        Text("Voice Note (\(formattedTime(time: audioManager.duration)))")
                            .font(.caption)
                            .foregroundColor(isFromCurrentUser ? .white : .primary)
                    }
                }
                
                if audioManager.duration > 0 {
                    ProgressView(value: audioManager.currentTime, total: audioManager.duration)
                        .progressViewStyle(LinearProgressViewStyle(tint: isFromCurrentUser ? .white : .orange))
                }
            }
        }
        .padding(12)
        .background(isFromCurrentUser ? Color(hex: "#24BAEC") : Color(.systemGray6))
        .cornerRadius(15)
        .onAppear {
            if audioData == nil {
                Task {
                    await downloadAudioFile()
                }
            }
        }
        .onDisappear {
            audioManager.stopPlayback()
        }
    }
    
    private func formattedTime(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func downloadAudioFile() async {
        guard let url = URL(string: audioUrl) else { return }
        
        isDownloading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.audioData = data
        } catch {
            print("Error downloading audio file: \(error.localizedDescription)")
        }
        isDownloading = false
    }
}

// Voice Recorder Button
private struct VoiceRecorderButton: View {
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

// Report User Sheet
private struct ReportUserSheet: View {
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

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
    // Support both regular users and partners
    // authVM is always required (always in environment), but we use Firebase Auth for user ID
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var messageText: String = ""
    @State private var isShowingReportSheet = false
    @State private var alertMessage: String = ""
    @State private var showingAlert = false
    @State private var reportReason: String = ""
    
    // Use a dedicated state variable for the PhotosPicker item
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // ⭐️ UPDATED: Get current user ID from Firebase Auth directly
    // This works for both regular users and partners since both authenticate via Firebase Auth
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
        
    // ⭐️ Safely calculate the partner's ID using the helper method
    private var partnerId: String? {
        guard let userId = currentUserId else { return nil }
        return chat.getPartnerId(currentUserId: userId)
    }

    private var isMuted: Bool {
        guard let userId = currentUserId, let muted = chat.mutedBy?[userId] else { return false }
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
            if let partnerId = self.partnerId {
                            viewModel.subscribeToPartnerStatus(partnerId: partnerId)
                        }
        }
        .onDisappear {
            viewModel.messagesListener?.remove()
            viewModel.unsubscribeFromPartnerStatus()
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
        HStack(spacing: 25) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .background(Circle().fill(Color(.systemGray6)).frame(width: 40, height: 40))
            }
            
            
//            KFImage(chat.partnerProfilePictureURL)
//                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
//                .resizable()
//                .scaledToFill()
//                .frame(width: 40, height: 40)
//                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(chat.getPartnerDisplayName(currentUserId: currentUserId ?? "") ?? "Unknown User")
                    .font(.headline)
                    .lineLimit(1)
                
                if isMuted {
                    Text("Conversation Muted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let partnerId = self.partnerId, viewModel.typingStatus.contains(partnerId) {
                    Text("Typing...")
                    .font(.caption)
                    .foregroundColor(.green)
                } else if let status = viewModel.partnerStatus {
                   statusText(for: status) // <-- Call the new helper function
                } else {
                                        // Fallback if status is not loaded yet
                                        Text("Offline")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
            }
            
            Spacer()

            Menu {
                Button(action: {
                    Task {
                        if let userId = currentUserId, let chatId = chat.id {
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
                    .background(Circle().fill(Color(.systemGray6)).frame(width: 40, height: 40))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .sheet(isPresented: $isShowingReportSheet) {
            ReportUserSheet(reportReason: $reportReason) { reason in
                Task {
                    if let chatId = chat.id, let recipientId = self.partnerId {
                        await viewModel.reportUser(chatId: chatId, recipientId: recipientId, reason: reason)
                    }
                }
            }
        }
    }
    
    private func statusText(for status: UserStatus) -> some View {
        let lastSeenDate = status.lastSeen?.dateValue()
            
        // 1. If explicitly marked as online, show "Online".
        if status.isOnline == true {
            return Text("Online")
                .font(.caption)
                .foregroundColor(.green)
        }
            
        // 2. If not online, use the lastSeen timestamp.
        guard let safeLastSeenDate = lastSeenDate else {
            // Fallback: If no lastSeen timestamp exists (e.g., brand new user or first load),
            // we must default to a definitive offline state.
            return Text("Offline")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        // 3. Calculate and format the "Last seen" time.
        let timeSinceLastSeen = Date().timeIntervalSince(safeLastSeenDate)
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60

        if timeSinceLastSeen > sevenDays {
            // If it's too old (> 7 days), show the full date (e.g., "Sep 20, 2025 at 10:30 AM")
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let absoluteTime = formatter.string(from: safeLastSeenDate)
                
            return Text("Last seen \(absoluteTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            // For recent times, use the RelativeDateTimeFormatter (e.g., "5 min ago" or "Yesterday")
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            // Note: The formatter handles "ago" implicitly in many languages, but we add it for clarity here if needed.
            let relativeTime = formatter.localizedString(for: safeLastSeenDate, relativeTo: Date())
                
            return Text("Last seen \(relativeTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // ⭐️ FIX: Use the extracted content view here
                MessageListContent(
                    viewModel: viewModel,
                    chat: chat,
                    currentUserId: self.currentUserId, // Use the computed property from ChatView
                    shouldShowDateHeader: shouldShowDateHeader // Pass the helper function
                )
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


                    private func shouldShowDateHeader(currentMessageDate: Date, previousMessageDate: Date?) -> Bool {
                        guard let previousDate = previousMessageDate else {
                            return true // Always show the header for the very first message
                        }
                        let calendar = Calendar.current
                        return !calendar.isDate(currentMessageDate, inSameDayAs: previousDate)
                    }
    
    private var messageInputView: some View {
        MessageInputView(
            messageText: $messageText,
            onSend: {
                if !messageText.isEmpty {
                    if let chatId = chat.id, let recipientId = self.partnerId {
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
                if let chatId = chat.id, let recipientId = self.partnerId {
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
                    if let chatId = chat.id, let recipientId = self.partnerId {
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

// MARK: - Extracted Row Content
private struct MessageListRow: View {
    @ObservedObject var viewModel: MessageViewModel
    let message: Message
    let index: Int
    let chat: Chat
    let currentUserId: String?
    let shouldShowDateHeader: (Date, Date?) -> Bool

    // We must compute the variables here instead of the ForEach closure
    private var previousMessage: Message? {
        index > 0 ? viewModel.messages[index - 1] : nil
    }
    
    private var messageDate: Date {
        message.timestamp.dateValue()
    }
    
    private var isCurrent: Bool {
        message.senderId == self.currentUserId
    }

    var body: some View {
        VStack(spacing: 0) { // Use VStack to combine the optional header and the row
            // 1. Check if the date has changed since the last message
            if shouldShowDateHeader(messageDate, previousMessage?.timestamp.dateValue()) {
                DateHeaderView(date: messageDate)
                    .padding(.vertical, 10)
                    .id("date-\(message.id ?? UUID().uuidString)")
            }
                
            // 2. The Message Row
            MessageRow(
                message: message,
                isFromCurrentUser: isCurrent,
                chat: chat,
                currentUserId: self.currentUserId,
                onLongPress: {
                    if isCurrent {
                        Task {
                            if let chatId = chat.id, let messageId = message.id {
                                await viewModel.deleteMessage(chatId: chatId, messageId: messageId)
                            }
                        }
                        HapticManager.shared.play(feedback: .medium)
                    }
                }
            )
            .id(message.id) // The message row ID
        }
    }
}

// MARK: - Message List Content View (Simplified)
private struct MessageListContent: View {
    @ObservedObject var viewModel: MessageViewModel
    let chat: Chat
    let currentUserId: String?
    let shouldShowDateHeader: (Date, Date?) -> Bool

    var body: some View {
        LazyVStack(spacing: 10) {
            if viewModel.canLoadMoreMessages {
                // Ensure the ProgressView is explicitly typed if you still had that error
                ProgressView("Loading...")
                    .progressViewStyle(.circular)
                    .onAppear {
                        if let chatId = chat.id {
                            viewModel.loadMoreMessages(chatId: chatId)
                        }
                    }
            }
                            
            // ⭐️ FIX: Use the extracted MessageListRow
            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                MessageListRow(
                    viewModel: viewModel,
                    message: message,
                    index: index,
                    chat: chat,
                    currentUserId: self.currentUserId,
                    shouldShowDateHeader: shouldShowDateHeader
                )
            }
        }
        .padding()
    }
}

// A view for a single message.
private struct MessageRow: View {
    let message: Message
    let isFromCurrentUser: Bool
    let chat: Chat
    let currentUserId: String? // Corrected property
    let onLongPress: () -> Void

    // Computed properties to replace the old direct properties
    private var partnerAvatarURL: URL? {
        chat.getPartnerProfilePictureURL(currentUserId: currentUserId ?? "")
    }

    private var partnerDisplayName: String? {
        chat.getPartnerDisplayName(currentUserId: currentUserId ?? "")
    }

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
    
    // MARK: - Subviews
    
    // ⭐️ FIX: The partnerAvatar must now use the computed 'partnerAvatarURL'
    private var partnerAvatar: some View {
        // Assuming you use Kingfisher or a similar library for AsyncImage loading
        KFImage(partnerAvatarURL)
            .placeholder {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
            }
            .resizable()
            .scaledToFill()
            .frame(width: 30, height: 30)
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

    @Binding var selectedPhotoItem: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void

    @Binding var isRecording: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    @State private var hasMeasuredHeight = false

    // Initialize inputHeight directly to the minHeight (35).
    @State private var inputHeight: CGFloat = 35
    
    private let textVerticalPadding: CGFloat = 8
    private let minHeight: CGFloat = 19 + 2 * 8 // ~35
    private let maxHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 15) {
                
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
                
                // --- DYNAMIC TEXT INPUT FIELD ---
                GeometryReader { zStackProxy in
                    ZStack(alignment: .topLeading) {
                        // 1. Hidden Text for measuring height
                        Text(messageText + " ")
                            .font(.body)
                            .padding(.vertical, textVerticalPadding)
                            .padding(.horizontal, 5)
                            .lineLimit(nil)
                            .frame(width: zStackProxy.size.width, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { textGeometry in
                                    Color.clear
                                        .onAppear {
                                            DispatchQueue.main.async {
                                                updateHeight(newTextHeight: textGeometry.size.height)
                                            }
                                        }
                                        .onChange(of: messageText) { _, _ in
                                            DispatchQueue.main.async {
                                                updateHeight(newTextHeight: textGeometry.size.height)
                                            }
                                        }
                                }
                            )
                            .opacity(0)

                        // 2. Placeholder
                        if messageText.isEmpty {
                            Text("Type a message...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.vertical, textVerticalPadding)
                                .padding(.horizontal, 10)
                        }

                        // 3. Visible TextEditor
                        TextEditor(text: $messageText)
                            .font(.body)
                            .frame(height: inputHeight)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .frame(height: max(minHeight, min(inputHeight, maxHeight)))
                    .background(Color(.systemGray6))
                    .cornerRadius(18)
                    .alignmentGuide(.bottom) { d in d[.bottom] }
                }
                .frame(height: max(minHeight, min(inputHeight, maxHeight)))


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
        .onAppear {
            inputHeight = minHeight
        }
        
    }

    
    private func updateHeight(newTextHeight: CGFloat) {
        let buffer: CGFloat = 5
        let newHeight = newTextHeight + buffer
        let clampedHeight = min(max(newHeight, minHeight), maxHeight)

        if abs(clampedHeight - inputHeight) > 1 {
            withAnimation(.easeOut(duration: 0.1)) {
                inputHeight = clampedHeight
            }
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


private struct DateHeaderView: View {
    let date: Date

    var body: some View {
        Text(formattedDate(from: date))
            .font(.caption).bold()
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(.systemGray))) // Aesthetic background for the date
    }

    private func formattedDate(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            // Format as Sun, Sep 21
            let formatter = DateFormatter()
            // Check if the year is the current year. If not, include the year.
            if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
                formatter.dateFormat = "E, MMM d" // e.g., Sun, Sep 21
            } else {
                formatter.dateFormat = "E, MMM d, yyyy" // e.g., Sun, Sep 21, 2024
            }
            return formatter.string(from: date)
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

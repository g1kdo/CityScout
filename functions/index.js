const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK with your project's default credentials
admin.initializeApp();
const db = admin.firestore();

// A Cloud Function that triggers every time a new message is written to a chat's `messages` subcollection.
exports.onNewMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        // Get the new message data
        const newMessage = snapshot.data();
        const chatId = context.params.chatId;

        // Exit if the message is from a system or invalid user
        if (!newMessage.senderId || !newMessage.receiverId) {
            console.log("Message is missing sender or recipient ID.");
            return null;
        }

        const senderId = newMessage.senderId;
        const recipientId = newMessage.receiverId;

        // 1. Update the chat document with the last message and unread count
        const chatRef = db.collection("chats").doc(chatId);

        // This is a Firestore transaction. It ensures that the unread count update
        // is atomic, meaning it won't be overwritten by a concurrent write.
        try {
            await db.runTransaction(async (transaction) => {
                const chatDoc = await transaction.get(chatRef);
                
                if (!chatDoc.exists) {
                    // This case should ideally not happen if a new chat is created correctly on the client,
                    // but it's a good safety check.
                    console.log("Chat document does not exist. The client may not have created it.");
                    return null;
                }
                
                const chatData = chatDoc.data();
                const currentUnreadCount = chatData.unreadCount || {};
                
                // Increment the recipient's unread count
                const newUnreadCount = { ...currentUnreadCount, [recipientId]: (currentUnreadCount[recipientId] || 0) + 1 };
                
                // Update the chat document
                transaction.update(chatRef, {
                    lastMessage: newMessage,
                    lastUpdated: newMessage.timestamp,
                    unreadCount: newUnreadCount,
                });
            });
        } catch (error) {
            console.error("Transaction failed: ", error);
            return null;
        }

        // 2. Fetch the sender's display name and the recipient's FCM token
        const senderUserDoc = await db.collection("users").doc(senderId).get();
        const recipientUserDoc = await db.collection("users").doc(recipientId).get();

        const senderName = senderUserDoc.data()?.displayName ?? "A user";
        const recipientToken = recipientUserDoc.data()?.fcmToken;

        // Determine the notification body based on message type
        let notificationBody = "New message";
        if (newMessage.messageType === "text" && newMessage.text) {
            notificationBody = newMessage.text;
        } else if (newMessage.messageType === "image") {
            notificationBody = "Sent an image";
        } else if (newMessage.messageType === "voice") {
            notificationBody = "Sent a voice note";
        }

        // If a token exists, send the notification
        if (recipientToken) {
            const payload = {
                notification: {
                    title: senderName,
                    body: notificationBody,
                    sound: "default",
                },
                data: {
                    chatId: chatId,
                    senderId: senderId,
                },
                token: recipientToken,
            };

            console.log("Sending push notification to:", recipientId);
            try {
                const response = await admin.messaging().send(payload);
                console.log("Successfully sent message:", response);
            } catch (error) {
                console.error("Error sending message:", error);
            }
        } else {
            console.log("Recipient has no FCM token. Not sending push notification.");
        }

        return null;
    });

// NEW: A Cloud Function that triggers when a message is deleted
exports.onMessageDeleted = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onDelete(async (snapshot, context) => {
        const chatId = context.params.chatId;
        
        // Update the last message in the chat document.
        // This is important to ensure the conversation history is correctly displayed.
        const chatRef = db.collection('chats').doc(chatId);
        
        try {
            // Find the new last message after deletion.
            const messagesQuery = await chatRef.collection('messages').orderBy('timestamp', 'desc').limit(1).get();
            const lastMessage = messagesQuery.docs.length > 0 ? messagesQuery.docs[0].data() : null;

            await chatRef.update({
                lastMessage: lastMessage,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log("Chat document updated after message deletion.");
        } catch (error) {
            console.error("Error updating chat document after message deletion:", error);
        }
        
        return null;
    });

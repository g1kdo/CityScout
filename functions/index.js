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
        if (!newMessage.senderId || !newMessage.recipientId) {
            console.log("Message is missing sender or recipient ID.");
            return null;
        }

        const senderId = newMessage.senderId;
        const recipientId = newMessage.recipientId;

        // 1. Update the chat document with the last message and unread count
        const chatRef = db.collection("chats").doc(chatId);

        // This is a Firestore transaction. It ensures that the unread count update
        // is atomic, meaning it won't be overwritten by a concurrent write.
        await db.runTransaction(async (transaction) => {
            const chatDoc = await transaction.get(chatRef);
            if (!chatDoc.exists) {
                console.log("Chat document does not exist. Creating a new one.");
                transaction.set(chatRef, {
                    lastMessage: newMessage,
                    lastUpdated: newMessage.timestamp,
                    participants: [senderId, recipientId],
                    // Initialize unread counts for both users
                    unreadCount: {
                        [senderId]: 0,
                        [recipientId]: 1,
                    },
                });
            } else {
                // Get the current unread count map
                const currentUnreadCount = chatDoc.data().unreadCount || {};

                // Increment the recipient's unread count
                const newUnreadCount = { ...currentUnreadCount, [recipientId]: (currentUnreadCount[recipientId] || 0) + 1 };

                // Update the chat document
                transaction.update(chatRef, {
                    lastMessage: newMessage,
                    lastUpdated: newMessage.timestamp,
                    unreadCount: newUnreadCount,
                });
            }
        });

        // 2. Fetch the recipient's FCM token to send a push notification
        const recipientUserRef = db.collection("users").doc(recipientId);
        const recipientUserDoc = await recipientUserRef.get();
        const recipientToken = recipientUserDoc.data().fcmToken;
        const senderName = newMessage.senderDisplayName;

        // If a token exists, send the notification
        if (recipientToken) {
            const payload = {
                notification: {
                    title: senderName,
                    body: newMessage.text,
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
    

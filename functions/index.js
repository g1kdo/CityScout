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

// NEW FUNCTION: Triggers on any change to the 'reviews' collection.
exports.updateDestinationRating = functions.firestore
    .document('reviews/{reviewId}')
    .onWrite(async (change, context) => {
        const reviewData = change.after.exists ? change.after.data() : null;
        const previousReviewData = change.before.exists ? change.before.data() : null;

        let destinationId;
        if (reviewData) {
            destinationId = reviewData.destinationId;
        } else if (previousReviewData) {
            destinationId = previousReviewData.destinationId;
        } else {
            return null; // No document to get destinationId from, so exit.
        }

        const reviewsRef = db.collection('reviews').where('destinationId', '==', destinationId);
        const reviewsSnapshot = await reviewsRef.get();
        
        let totalRating = 0;
        let uniqueAvatars = new Set();

        reviewsSnapshot.forEach(doc => {
            const review = doc.data();
            totalRating += review.rating;
            if (review.authorProfilePictureURL) {
                uniqueAvatars.add(review.authorProfilePictureURL);
            }
        });

        const reviewCount = reviewsSnapshot.size;
        const averageRating = reviewCount > 0 ? totalRating / reviewCount : 0;
        const participantAvatars = Array.from(uniqueAvatars);

        const destinationRef = db.collection('destinations').doc(destinationId);
        
        // Use a transaction for the update to ensure it's atomic
        return db.runTransaction(t => {
            return t.get(destinationRef).then(doc => {
                if (!doc.exists) {
                    console.error("Destination document does not exist:", destinationId);
                    return Promise.resolve();
                }
                t.update(destinationRef, {
                    rating: averageRating,
                    participantAvatars: participantAvatars
                });
            });
        }).catch(error => {
            console.error("Transaction failed: ", error);
        });
    });

// A Cloud Function that handles user deletion
exports.onUserDelete = functions.auth.user().onDelete(async (user) => {
    try {
        const userId = user.uid;

        // 1. Anonymize reviews by this user
        const reviewsRef = db.collection("reviews").where("authorId", "==", userId);
        const reviewsSnapshot = await reviewsRef.get();
        const reviewBatch = db.batch();
        reviewsSnapshot.forEach((doc) => {
            const reviewRef = doc.ref;
            reviewBatch.update(reviewRef, {
                authorId: null,
                authorDisplayName: "Anonymous",
                authorProfilePictureURL: null,
            });
        });
        await reviewBatch.commit();
        console.log(`Anonymized all reviews for user: ${userId}`);

        // 2. Anonymize chat messages sent by this user
        const chatsRef = db.collection("chats");
        const chatsSnapshot = await chatsRef.where("members", "array-contains", userId).get();
        const chatUpdatePromises = [];
        for (const chatDoc of chatsSnapshot.docs) {
            const chatId = chatDoc.id;
            const messagesRef = chatsRef.doc(chatId).collection("messages").where("senderId", "==", userId);
            const messagesSnapshot = await messagesRef.get();
            const messageBatch = db.batch();
            messagesSnapshot.forEach((doc) => {
                const messageRef = doc.ref;
                messageBatch.update(messageRef, {
                    senderId: null,
                });
            });
            chatUpdatePromises.push(messageBatch.commit());
        }
        await Promise.all(chatUpdatePromises);
        console.log(`Anonymized all chat messages for user: ${userId}`);

        // 3. Anonymize booking requests made by this user
        const bookingsRef = db.collection("bookings").where("userId", "==", userId);
        const bookingsSnapshot = await bookingsRef.get();
        const bookingBatch = db.batch();
        bookingsSnapshot.forEach((doc) => {
            const bookingRef = doc.ref;
            bookingBatch.update(bookingRef, {
                userId: null,
            });
        });
        await bookingBatch.commit();
        console.log(`Anonymized all booking requests for user: ${userId}`);

        // 4. Delete the user's profile document
        const userDocRef = db.collection("users").doc(userId);
        await userDocRef.delete();
        console.log(`Deleted user document for user: ${userId}`);

        // 5. Delete the user's profile picture from Firebase Storage
        if (user.photoURL) {
            const fileRef = storage.bucket().file(`profile_pictures/${userId}`);
            try {
                await fileRef.delete();
                console.log(`Deleted profile picture for user: ${userId}`);
            } catch (error) {
                // Handle cases where the file might not exist, but don't stop the function.
                console.warn(`Could not delete profile picture for user: ${userId}, file might not exist. Error: ${error.message}`);
            }
        }
        
        return null;
    } catch (error) {
        console.error("Error handling user deletion:", error);
        return null;
    }
});
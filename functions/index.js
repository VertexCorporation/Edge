const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    
    // Ensure we have a senderId and at least one receiver
    if (!message.senderId) return null;

    const senderId = message.senderId;
    let receivers = [];

    // For 1-to-1 chats, we have receiverId
    if (message.receiverId && message.receiverId !== "") {
      receivers = [message.receiverId];
    } else {
      // For group chats, we must fetch the chat document to get participants
      const chatId = context.params.chatId;
      const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
      if (!chatDoc.exists) return null;
      
      const chatData = chatDoc.data();
      const participants = chatData.participants || [];
      // Remove sender from receivers
      receivers = participants.filter(id => id !== senderId);
    }

    if (receivers.length === 0) return null;

    // Get sender's info (name or username)
    const senderDoc = await admin.firestore().collection("usernames").where("userId", "==", senderId).limit(1).get();
    let senderName = "Biri";
    if (!senderDoc.empty) {
      const data = senderDoc.docs[0].data();
      senderName = data.name || data.username || "Biri";
    }

    const payload = {
      notification: {
        title: `Yeni mesaj: ${senderName}`,
        body: message.type === 'text' ? 'Sana bir mesaj gönderdi.' : 'Sana bir dosya gönderdi.',
        sound: 'default',
      }
    };

    // Send to all receivers
    const tokens = [];
    for (const receiverId of receivers) {
      const userDoc = await admin.firestore().collection("usernames").where("userId", "==", receiverId).limit(1).get();
      if (!userDoc.empty) {
        const token = userDoc.docs[0].data().fcmToken;
        if (token) {
          tokens.push(token);
        }
      }
    }

    if (tokens.length > 0) {
      try {
        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log("Bildirimler başarıyla gönderildi:", response);
      } catch (error) {
        console.error("Bildirim gönderilirken hata oluştu:", error);
      }
    }

    return null;
  });

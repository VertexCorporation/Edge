const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const message = snap.data();
      if (!message.senderId) return null;

      const senderId = message.senderId;
      let receivers = [];

      if (message.receiverId && message.receiverId !== "") {
        receivers = [message.receiverId];
      } else {
        const chatId = context.params.chatId;
        const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
        if (!chatDoc.exists) return null;

        const chatData = chatDoc.data();
        const participants = chatData.participants || [];
        receivers = participants.filter((id) => id !== senderId);
      }

      if (receivers.length === 0) return null;

      const senderDoc = await admin.firestore()
          .collection("usernames")
          .where("userId", "==", senderId)
          .limit(1)
          .get();

      let senderName = "Biri";
      if (!senderDoc.empty) {
        const data = senderDoc.docs[0].data();
        senderName = data.name || data.username || "Biri";
      }

      const tokens = [];
      for (const receiverId of receivers) {
        const userDoc = await admin.firestore()
            .collection("usernames")
            .where("userId", "==", receiverId)
            .limit(1)
            .get();
        if (!userDoc.empty) {
          const token = userDoc.docs[0].data().fcmToken;
          if (token) tokens.push(token);
        }
      }

      if (tokens.length > 0) {
        try {
          const response = await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
              title: `Yeni mesaj: ${senderName}`,
              body: message.type === "text" ?
                "Sana bir mesaj gönderdi." :
                "Sana bir dosya gönderdi.",
            },
          });
          console.log("Bildirimler başarıyla gönderildi:", response);
        } catch (error) {
          console.error("Bildirim gönderilirken hata oluştu:", error);
        }
      }

      return null;
    });

exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  const {uid, email, displayName, photoURL} = user;
  const name = displayName || "Kullanıcı";
  const db = admin.firestore();

  await db.collection("users").doc(uid).set({
    name,
    email: email || "",
    role: "Geliştirici",
    isVertex: false,
    isOnline: true,
    photoURL: photoURL || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  let username = email ?
    email.split("@")[0].toLowerCase().replace(/[^a-z0-9_]/g, "") :
    uid.slice(0, 8);
  if (!username) {
    username = uid.slice(0, 8);
  }

  let suffix = 1;
  let usernameRef = db.collection("usernames").doc(username);
  let usernameDoc = await usernameRef.get();
  while (usernameDoc.exists && usernameDoc.data().userId !== uid) {
    username = `${username}${suffix}`;
    suffix++;
    usernameRef = db.collection("usernames").doc(username);
    usernameDoc = await usernameRef.get();
  }

  await usernameRef.set({
    userId: uid,
    name,
    email: email || "",
    role: "Geliştirici",
    isOnline: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return null;
});

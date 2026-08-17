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

const ADMIN_ROLE = "Yönetici";

async function setUserRole(uid, role) {
  const db = admin.firestore();
  await db.collection("users").doc(uid).set({role}, {merge: true});

  const usernameSnap = await db.collection("usernames")
      .where("userId", "==", uid)
      .limit(1)
      .get();

  if (!usernameSnap.empty) {
    await usernameSnap.docs[0].ref.set({role}, {merge: true});
  }
}

async function setUserRoleByEmail(email, role) {
  const normalized = email.trim().toLowerCase();
  try {
    const userRecord = await admin.auth().getUserByEmail(normalized);
    await setUserRole(userRecord.uid, role);
    return userRecord.uid;
  } catch (authError) {
    const snap = await admin.firestore().collection("users")
        .where("email", "==", normalized)
        .limit(1)
        .get();
    if (snap.empty) {
      throw new functions.https.HttpsError("not-found", "Kullanıcı bulunamadı.");
    }
    await setUserRole(snap.docs[0].id, role);
    return snap.docs[0].id;
  }
}

/** One-time bootstrap: listed emails can claim Yönetici on login. */
exports.claimBootstrapAdmin = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }

  const email = (context.auth.token.email || "").toLowerCase();
  const bootstrapEmails = [
    "rel0adneverdone@gmail.com",
    "mustawtfa@gmail.com",
  ];

  if (!bootstrapEmails.includes(email)) {
    throw new functions.https.HttpsError("permission-denied", "Yetkisiz.");
  }

  await setUserRole(context.auth.uid, ADMIN_ROLE);
  return {success: true, role: ADMIN_ROLE};
});

/** Yönetici can promote other users by email. */
exports.assignUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }

  const callerDoc = await admin.firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();
  const callerRole = callerDoc.data()?.role;
  const canAssignRoles = callerRole === ADMIN_ROLE || callerRole === "Mod";
  if (!canAssignRoles) {
    throw new functions.https.HttpsError(
        "permission-denied", "Yönetici veya Mod gerekli.");
  }

  const PROTECTED_ADMIN_EMAILS = [
    "rel0adneverdone@gmail.com",
    "mustawtfa@gmail.com",
  ];

  const uid = data.uid;
  const email = (data.email || "").trim().toLowerCase();
  const role = data.role || "Üye";
  const allowedRoles = ["Üye", "Geliştirici", "Test", "Mod", "Support"];
  if (!email && !uid) {
    throw new functions.https.HttpsError("invalid-argument", "E-posta gerekli.");
  }
  if (email && PROTECTED_ADMIN_EMAILS.includes(email)) {
    throw new functions.https.HttpsError(
        "permission-denied", "Bu hesabın rolü panelden değiştirilemez.");
  }
  if (!allowedRoles.includes(role)) {
    throw new functions.https.HttpsError(
        "invalid-argument", "Bu rol atanamaz.");
  }

  let assignedUid = uid;
  if (assignedUid) {
    const target = await admin.auth().getUser(assignedUid).catch(() => null);
    const targetEmail = (target?.email || email || "").toLowerCase();
    if (PROTECTED_ADMIN_EMAILS.includes(targetEmail)) {
      throw new functions.https.HttpsError(
          "permission-denied", "Bu hesabın rolü panelden değiştirilemez.");
    }
    await setUserRole(assignedUid, role);
  } else {
    assignedUid = await setUserRoleByEmail(email, role);
  }
  return {success: true, uid: assignedUid, role};
});

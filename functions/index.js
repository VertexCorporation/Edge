const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const BOOTSTRAP_ADMIN_EMAILS = [
  "rel0adneverdone@gmail.com",
  "mustawtfa@gmail.com",
  "egemen.topcuoglu6740@gmail.com",
];

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
      } else {
        const senderUser = await admin.firestore()
            .collection("users").doc(senderId).get();
        if (senderUser.exists) {
          const data = senderUser.data();
          senderName = data.name || data.username || "Biri";
        }
      }

      const tokens = [];
      for (const receiverId of receivers) {
        const userDoc = await admin.firestore()
            .collection("users").doc(receiverId).get();
        if (userDoc.exists) {
          const data = userDoc.data();
          if (data.fcmToken) tokens.push(data.fcmToken);
          if (Array.isArray(data.fcmTokens)) {
            data.fcmTokens.forEach((t) => tokens.push(t));
          }
        }

        const usernameDoc = await admin.firestore()
            .collection("usernames")
            .where("userId", "==", receiverId)
            .limit(1)
            .get();
        if (!usernameDoc.empty) {
          const token = usernameDoc.docs[0].data().fcmToken;
          if (token) tokens.push(token);
        }
      }

      const uniqueTokens = [...new Set(tokens.filter(Boolean))];

      if (uniqueTokens.length > 0) {
        try {
          const response = await admin.messaging().sendEachForMulticast({
            tokens: uniqueTokens,
            notification: {
              title: `Yeni mesaj: ${senderName}`,
              body: message.type === "text" ?
                "Sana bir mesaj gönderdi." :
                "Sana bir dosya gönderdi.",
            },
            webpush: {
              notification: {
                title: `Yeni mesaj: ${senderName}`,
                body: message.type === "text" ?
                  "Sana bir mesaj gönderdi." :
                  "Sana bir dosya gönderdi.",
                icon: "/icons/Icon-192.png",
              },
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
  const db = admin.firestore();
  const existingSnap = await db.collection("users").doc(uid).get();
  const existing = existingSnap.data() || {};
  const cortexUsername = typeof existing.username === "string" ?
    existing.username.trim() : "";
  const isCortex = cortexUsername.length > 0 ||
    existing.hasCortexSubscription != null ||
    (typeof existing.accountType === "string" &&
      existing.accountType.length > 0 &&
      existing.accountType !== "anonymous");
  const name = existing.name || cortexUsername || displayName || "Kullanıcı";

  const edgeFields = {
    email: email || existing.email || "",
    isOnline: true,
    isEdge: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    photoURL: photoURL || existing.photoURL || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!existing.name) {
    edgeFields.name = name;
  }
  if (existing.isVertex !== true) {
    edgeFields.isVertex = isCortex;
  }
  await db.collection("users").doc(uid).set(edgeFields, {merge: true});

  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists || !userSnap.data().role) {
    await db.collection("users").doc(uid).set({role: "Üye"}, {merge: true});
  }

  let username = cortexUsername ?
    cortexUsername.toLowerCase().replace(/[^a-z0-9_]/g, "") :
    (email ?
      email.split("@")[0].toLowerCase().replace(/[^a-z0-9_]/g, "") :
      uid.slice(0, 8));
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

  const usernamePayload = {
    userId: uid,
    name,
    email: email || "",
    isOnline: true,
    isEdge: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!usernameDoc.exists || !usernameDoc.data()?.role) {
    usernamePayload.role = "Üye";
  }
  await usernameRef.set(usernamePayload, {merge: true});

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
  const bootstrapEmails = BOOTSTRAP_ADMIN_EMAILS;

  if (!bootstrapEmails.includes(email)) {
    throw new functions.https.HttpsError("permission-denied", "Yetkisiz.");
  }

  await setUserRole(context.auth.uid, ADMIN_ROLE);
  for (const bootstrapEmail of bootstrapEmails) {
    try {
      await setUserRoleByEmail(bootstrapEmail, ADMIN_ROLE);
    } catch (error) {
      console.log("Bootstrap admin restore skipped:", bootstrapEmail, error);
    }
  }
  return {success: true, role: ADMIN_ROLE};
});

/** Yönetici can promote other users by email. */
exports.assignUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }

  const callerEmail = (context.auth.token.email || "").toLowerCase();
  const callerDoc = await admin.firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();
  const callerRole = callerDoc.data()?.role;
  const isBootstrapAdmin = BOOTSTRAP_ADMIN_EMAILS.includes(callerEmail);
  const canAssignRoles =
    callerRole === ADMIN_ROLE || callerRole === "Mod" || isBootstrapAdmin;
  if (!canAssignRoles) {
    throw new functions.https.HttpsError(
        "permission-denied", "Yönetici veya Mod gerekli.");
  }

  const PROTECTED_ADMIN_EMAILS = BOOTSTRAP_ADMIN_EMAILS;

  const uid = data.uid;
  const email = (data.email || "").trim().toLowerCase();
  const role = data.role || "Üye";
  const allowedRoles = ["Üye", "Geliştirici", "Test", "Mod", "Support"];
  if (!email && !uid) {
    throw new functions.https.HttpsError("invalid-argument", "Kullanıcı gerekli.");
  }
  if (email && PROTECTED_ADMIN_EMAILS.includes(email)) {
    throw new functions.https.HttpsError(
        "permission-denied", "Bu hesabın rolü panelden değiştirilemez.");
  }
  if (!allowedRoles.includes(role)) {
    throw new functions.https.HttpsError(
        "invalid-argument", "Bu rol atanamaz.");
  }

  try {
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
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("assignUserRole failed:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Rol kaydedilemedi. Bağlantıyı kontrol et, sonra tekrar dene.");
  }
});

/** Resolve a Cortex username to the Firebase Auth email for Edge login. */
exports.resolveLoginEmail = functions.https.onCall(async (data) => {
  const raw = String((data && data.username) || "").trim();
  if (!raw) {
    throw new functions.https.HttpsError("invalid-argument", "Kullanıcı gerekli.");
  }
  if (raw.includes("@")) {
    return {email: raw.toLowerCase()};
  }

  const db = admin.firestore();
  const sanitized = raw.toLowerCase().replace(/[^a-z0-9_]/g, "");
  const candidates = Array.from(new Set([raw, raw.toLowerCase(), sanitized]
      .filter(Boolean)));

  for (const candidate of candidates) {
    const byUsername = await db.collection("users")
        .where("username", "==", candidate)
        .limit(1)
        .get();
    if (!byUsername.empty) {
      const email = (byUsername.docs[0].data().email || "").trim().toLowerCase();
      if (email.includes("@")) return {email};
    }
  }

  for (const key of candidates) {
    const usernameDoc = await db.collection("usernames").doc(key).get();
    if (usernameDoc.exists) {
      const email = (usernameDoc.data().email || "").trim().toLowerCase();
      if (email.includes("@")) return {email};
    }
  }

  throw new functions.https.HttpsError("not-found", "Kullanıcı bulunamadı.");
});

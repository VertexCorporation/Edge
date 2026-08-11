import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';
import 'crypto_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CryptoService _cryptoService = CryptoService();

  String get currentUserId => _auth.currentUser!.uid;

  /// Ensure the current user has keys generated and public key is in Firestore
  Future<void> initializeKeys() async {
    final hasKeys = await _cryptoService.hasKeys();
    if (!hasKeys) {
      final publicKeyPem = await _cryptoService.generateAndStoreKeys();
      await _firestore.collection('users').doc(currentUserId).set(
        {'publicKey': publicKeyPem},
        SetOptions(merge: true),
      );
    } else {
      // Ensure it's in firestore
      final publicKey = await _cryptoService.getPublicKey();
      if (publicKey != null) {
        await _firestore.collection('users').doc(currentUserId).set(
          {'publicKey': publicKey},
          SetOptions(merge: true),
        );
      }
    }
  }

  /// Get list of users to chat with
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get or create a chat ID for two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  /// Get messages stream for a specific chat, decrypted
  Stream<List<Map<String, dynamic>>> getMessages(String receiverId) {
    final chatId = getChatId(currentUserId, receiverId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> messages = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            
            // If we are the sender, we can't easily decrypt unless we saved our own copy
            // For true E2EE, we should save a copy encrypted with OUR public key, 
            // OR save it unencrypted in a local DB (like sqflite).
            // For simplicity in this demo, we'll try to decrypt if we are receiver.
            // If we are sender, we might just show "Sent Message" or we need to encrypt twice.
            // Let's implement encrypting twice: once for receiver, once for self.
            String decryptedText = '[Şifreli Mesaj]';
            try {
              if (data['senderId'] == currentUserId && data['selfEncryptedMessage'] != null) {
                 decryptedText = await _cryptoService.decryptMessage(
                   data['selfEncryptedMessage'], 
                   data['selfEncryptedKey']
                 );
              } else if (data['receiverId'] == currentUserId && data['encryptedMessage'] != null) {
                 decryptedText = await _cryptoService.decryptMessage(
                   data['encryptedMessage'], 
                   data['encryptedKey']
                 );
              }
            } catch (e) {
              decryptedText = '[Şifre Çözülemedi]';
            }

            messages.add({
              'id': doc.id,
              'senderId': data['senderId'],
              'receiverId': data['receiverId'],
              'text': decryptedText,
              'timestamp': data['timestamp'],
              'type': data['type'] ?? 'text',
            });
          }
          return messages;
        });
  }

  /// Send a text message
  Future<void> sendMessage(String receiverId, String text, {String type = 'text'}) async {
    final chatId = getChatId(currentUserId, receiverId);
    
    // Get receiver's public key
    final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    final receiverPublicKey = receiverDoc.data()?['publicKey'];
    
    if (receiverPublicKey == null) {
      throw Exception('Alıcının genel anahtarı (Public Key) bulunamadı.');
    }

    // Get our own public key
    final myPublicKey = await _cryptoService.getPublicKey();
    if (myPublicKey == null) throw Exception('Kendi genel anahtarımız bulunamadı.');

    // Encrypt for receiver
    final encryptedForReceiver = await _cryptoService.encryptMessage(text, receiverPublicKey);
    
    // Encrypt for self (so we can read our own sent messages)
    final encryptedForSelf = await _cryptoService.encryptMessage(text, myPublicKey);

    final messageData = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'encryptedMessage': encryptedForReceiver['message'],
      'encryptedKey': encryptedForReceiver['key'],
      'selfEncryptedMessage': encryptedForSelf['message'],
      'selfEncryptedKey': encryptedForSelf['key'],
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
    };

    // Save to chats subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
        
    // Also trigger the cloud function by writing to global messages (optional, or CF listens to chats/{chatId}/messages/{msgId})
    // Let's write a trigger doc to global messages for FCM
    await _firestore.collection('messages').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Send a file/image/audio securely
  Future<void> sendFile(String receiverId, Uint8List bytes, String type) async {

    // Generate AES key for file encryption
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);

    // Encrypt file bytes
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    final encryptedBytes = encrypter.encryptBytes(bytes, iv: iv).bytes;

    // Upload to Firebase Storage
    final fileName = const Uuid().v4();
    final ref = _storage.ref().child('e2ee_files').child('$fileName.enc');
    await ref.putData(Uint8List.fromList(encryptedBytes));
    final downloadUrl = await ref.getDownloadURL();

    // Create payload
    final payload = jsonEncode({
      'url': downloadUrl,
      'key': aesKey.base64,
      'iv': iv.base64,
      'fileName': fileName,
    });

    // Send payload as an E2EE message
    await sendMessage(receiverId, payload, type: type);
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';
import 'crypto.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CryptoService _cryptoService = CryptoService();

  String get currentUserId => _auth.currentUser!.uid;

  /// Ensure the current user has keys generated and public key is in Firestore
  Future<void> initializeKeys() async {
    final hasKeys = await _cryptoService.hasKeys();
    String? publicKey;
    
    if (!hasKeys) {
      publicKey = await _cryptoService.generateAndStoreKeys();
    } else {
      publicKey = await _cryptoService.getPublicKey();
    }
    
    if (publicKey != null) {
      try {
        final query = await _firestore.collection('usernames').where('userId', isEqualTo: currentUserId).limit(1).get();
        if (query.docs.isNotEmpty) {
          await _firestore.collection('usernames').doc(query.docs.first.id).set(
            {'publicKey': publicKey},
            SetOptions(merge: true),
          );
        }
      } catch (e) {
        // Silently fail if unable to write keys
      }
    }
  }

  /// Get list of users to chat with (Stream - Deprecated for large lists)
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore
        .collection('usernames')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['userId'] != currentUserId)
          .map((doc) => {
                'id': doc.data()['userId'], 
                'username': doc.id,
                ...doc.data()
              })
          .toList();
    });
  }

  /// Get a paginated list of users, filtering out those without a public key
  Future<Map<String, dynamic>> getUsersPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? searchQuery,
  }) async {
    Query query = _firestore.collection('usernames');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // If searching, we range-filter on document ID (username)
      final searchLower = searchQuery.toLowerCase();
      query = query
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: searchLower)
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$searchLower\uf8ff')
          .orderBy(FieldPath.documentId);
    } else {
      // If not searching, orderBy publicKey filters out docs where it is null/missing
      // We also order by documentId as a secondary tie-breaker for stable pagination
      query = query.orderBy('publicKey').orderBy(FieldPath.documentId);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Client-side filters
      if (data['userId'] == currentUserId) continue; // Skip self
      if (data['publicKey'] == null) continue; // Skip users without keys (useful for search query)
      
      users.add({
        'id': data['userId'],
        'username': doc.id,
        ...data,
      });
    }

    return {
      'users': users,
      'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == limit,
    };
  }

  /// Get or create a chat ID for two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  /// Create a new group chat
  Future<String> createGroupChat(
    String groupName, 
    List<String> memberIds, {
    String? communityId,
    bool isAnnouncementGroup = false,
  }) async {
    final chatId = const Uuid().v4(); // Unique ID for the group
    
    // Ensure current user is in the group
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    await _firestore.collection('chats').doc(chatId).set({
      'isGroup': true,
      'groupName': groupName,
      'participants': memberIds,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      // ignore: use_null_aware_elements
      if (communityId != null) 'communityId': communityId,
      if (isAnnouncementGroup) 'isAnnouncementGroup': true,
    });

    return chatId;
  }

  /// Create a new Community
  Future<String> createCommunity(String name, String description, List<String> memberIds) async {
    final communityId = const Uuid().v4();
    
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    // First create the announcements group
    final announcementGroupId = await createGroupChat(
      'Duyurular', 
      memberIds, 
      communityId: communityId,
      isAnnouncementGroup: true,
    );

    // Then create the community
    await _firestore.collection('communities').doc(communityId).set({
      'name': name,
      'description': description,
      'createdBy': currentUserId,
      'admins': [currentUserId],
      'members': memberIds,
      'announcementGroupId': announcementGroupId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return communityId;
  }

  /// Get Communities for the current user
  Stream<List<Map<String, dynamic>>> getCommunities() {
    return _firestore
        .collection('communities')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final comms = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      comms.sort((a, b) {
        final tA = a['createdAt'] as Timestamp?;
        final tB = b['createdAt'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });
      
      return comms;
    });
  }

  /// Get groups belonging to a specific community
  Stream<List<Map<String, dynamic>>> getCommunityGroups(String communityId) {
    return _firestore
        .collection('chats')
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get recent chats for the current user
  Stream<List<Map<String, dynamic>>> getRecentChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        // Find the other user's ID
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        return {
          'chatId': doc.id,
          'otherUserId': otherUserId,
          'isGroup': data['isGroup'] ?? false,
          'groupName': data['groupName'] ?? '',
          'lastMessageTimestamp': data['lastMessageTimestamp'],
        };
      }).where((chat) => chat['isGroup'] == true || chat['otherUserId'].isNotEmpty).toList();
      
      chats.sort((a, b) {
        final tA = a['lastMessageTimestamp'] as Timestamp?;
        final tB = b['lastMessageTimestamp'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });
      
      return chats;
    });
  }

  /// Get messages stream for a specific chat, decrypted
  Stream<List<Map<String, dynamic>>> getMessages(String chatId, {bool isGroup = false}) {
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
            
            String decryptedText = '[Mesaj]';
            
            if (isGroup) {
              // Group messages are not E2EE in this version
              decryptedText = data['text'] ?? '';
            } else {
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
            }

            messages.add({
              'id': doc.id,
              'senderId': data['senderId'],
              'receiverId': data['receiverId'] ?? '',
              'text': decryptedText,
              'timestamp': data['timestamp'],
              'type': data['type'] ?? 'text',
            });
          }
          return messages;
        });
  }

  /// Send a text message
  Future<void> sendMessage(String text, {
    String? receiverId, 
    String? explicitChatId, 
    bool isGroup = false, 
    String type = 'text',
    List<String> groupParticipants = const [],
  }) async {
    final chatId = explicitChatId ?? getChatId(currentUserId, receiverId!);
    Map<String, dynamic> messageData;

    if (isGroup) {
      messageData = {
        'senderId': currentUserId,
        'receiverId': '', // Not applicable for group
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
      };
    } else {
      // 1-to-1 E2EE Logic
      if (receiverId == null) throw Exception('Alıcı ID gerekli.');
      
      final receiverQuery = await _firestore.collection('usernames').where('userId', isEqualTo: receiverId).limit(1).get();
      if (receiverQuery.docs.isEmpty) throw Exception('Alıcı bulunamadı.');
      final receiverPublicKey = receiverQuery.docs.first.data()['publicKey'];
      if (receiverPublicKey == null) throw Exception('Alıcının genel anahtarı (Public Key) bulunamadı.');

      final myPublicKey = await _cryptoService.getPublicKey();
      if (myPublicKey == null) throw Exception('Kendi genel anahtarımız bulunamadı.');

      final encryptedForReceiver = await _cryptoService.encryptMessage(text, receiverPublicKey);
      final encryptedForSelf = await _cryptoService.encryptMessage(text, myPublicKey);

      messageData = {
        'senderId': currentUserId,
        'receiverId': receiverId,
        'encryptedMessage': encryptedForReceiver['message'],
        'encryptedKey': encryptedForReceiver['key'],
        'selfEncryptedMessage': encryptedForSelf['message'],
        'selfEncryptedKey': encryptedForSelf['key'],
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
      };
    }

    await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);

    if (isGroup) {
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        // participants should already exist from group creation
      }, SetOptions(merge: true));
    } else {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, receiverId],
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Send a file/image/audio securely
  Future<void> sendFile(Uint8List bytes, String type, {
    String? receiverId, 
    String? explicitChatId, 
    bool isGroup = false,
  }) async {

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
    await sendMessage(
      payload, 
      type: type, 
      receiverId: receiverId,
      explicitChatId: explicitChatId,
      isGroup: isGroup,
    );
  }
}

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';
import 'crypto.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CryptoService _cryptoService = CryptoService();

  final Map<String, _DecryptionCacheEntry> _decryptionCache = {};
  final Queue<_OutboundMessage> _outboundQueue = Queue();
  bool _processingOutboundQueue = false;

  String get currentUserId => _auth.currentUser!.uid;

  /// Ensure the current user has keys generated and public key is in Firestore
  Future<void> initializeKeys() async {
    final hasLocalKeys = await _cryptoService.hasKeys();

    if (hasLocalKeys) {
      final publicKey = await _cryptoService.getPublicKey();
      if (publicKey != null) {
        await _syncPublicKey(publicKey);
      }
      await _ensureKeyBackup();
      return;
    }

    if (await _tryRestoreKeysFromFirestore()) {
      final publicKey = await _cryptoService.getPublicKey();
      if (publicKey != null) {
        await _syncPublicKey(publicKey);
      }
      await _ensureKeyBackup();
      return;
    }

    final existingPublicKey = await _getExistingPublicKeyFromFirestore();
    if (existingPublicKey != null) {
      debugPrint(
        'E2EE: Local keys missing and no cloud backup found. '
        'Open Vertex Edge on your primary device once to sync encryption keys.',
      );
      return;
    }

    final publicKey = await _cryptoService.generateAndStoreKeys();
    await _syncPublicKey(publicKey);
    await _ensureKeyBackup();
  }

  Future<void> _syncPublicKey(String publicKey) async {
    try {
      final query = await _firestore
          .collection('usernames')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('usernames').doc(query.docs.first.id).set(
          {'publicKey': publicKey},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('E2EE: Failed to sync public key: $e');
    }
  }

  Future<String?> _getExistingPublicKeyFromFirestore() async {
    try {
      final query = await _firestore
          .collection('usernames')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first.data()['publicKey'] as String?;
    } catch (e) {
      debugPrint('E2EE: Failed to read public key: $e');
      return null;
    }
  }

  Future<bool> _tryRestoreKeysFromFirestore() async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userBackup = userDoc.data()?['e2eeKeyBackup'] as String?;
      if (userBackup != null && userBackup.isNotEmpty) {
        final restored = await _cryptoService.restoreFromKeyBackup(currentUserId, userBackup);
        if (restored) {
          debugPrint('E2EE: Restored encryption keys from users backup.');
          return true;
        }
      }

      final usernameQuery = await _firestore
          .collection('usernames')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        final usernameBackup =
            usernameQuery.docs.first.data()['e2eeKeyBackup'] as String?;
        if (usernameBackup != null && usernameBackup.isNotEmpty) {
          final restored =
              await _cryptoService.restoreFromKeyBackup(currentUserId, usernameBackup);
          if (restored) {
            debugPrint('E2EE: Restored encryption keys from usernames backup.');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('E2EE: Failed to restore keys: $e');
      return false;
    }
  }

  Future<void> _ensureKeyBackup() async {
    try {
      final backup = await _cryptoService.createKeyBackup(currentUserId);
      if (backup == null) return;

      await _firestore.collection('users').doc(currentUserId).set(
        {'e2eeKeyBackup': backup},
        SetOptions(merge: true),
      );

      final usernameQuery = await _firestore
          .collection('usernames')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        await _firestore.collection('usernames').doc(usernameQuery.docs.first.id).set(
          {'e2eeKeyBackup': backup},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('E2EE: Failed to back up keys: $e');
    }
  }

  Future<void> _ensureKeysForDecryption() async {
    if (await _cryptoService.hasKeys()) return;
    await initializeKeys();
  }

  Future<String> _decryptChatMessage(Map<String, dynamic> data) async {
    String? encryptedMessage;
    String? encryptedKey;

    if (data['senderId'] == currentUserId && data['selfEncryptedMessage'] != null) {
      encryptedMessage = data['selfEncryptedMessage'] as String?;
      encryptedKey = data['selfEncryptedKey'] as String?;
    } else if (data['receiverId'] == currentUserId && data['encryptedMessage'] != null) {
      encryptedMessage = data['encryptedMessage'] as String?;
      encryptedKey = data['encryptedKey'] as String?;
    }

    if (encryptedMessage == null || encryptedKey == null) {
      return '[Mesaj]';
    }

    try {
      return await _cryptoService.decryptMessage(encryptedMessage, encryptedKey);
    } catch (firstError) {
      debugPrint('E2EE: Decrypt failed, attempting key restore: $firstError');
      if (await _tryRestoreKeysFromFirestore()) {
        _decryptionCache.clear();
        return await _cryptoService.decryptMessage(encryptedMessage, encryptedKey);
      }
      await initializeKeys();
      if (await _cryptoService.hasKeys()) {
        _decryptionCache.clear();
        return await _cryptoService.decryptMessage(encryptedMessage, encryptedKey);
      }
      rethrow;
    }
  }

  String _encryptionFingerprint(Map<String, dynamic> data) {
    if (data['selfEncryptedMessage'] != null) {
      return '${data['selfEncryptedMessage']}|${data['selfEncryptedKey']}';
    }
    return '${data['encryptedMessage']}|${data['encryptedKey']}';
  }

  Future<String> _decryptChatMessageCached(String docId, Map<String, dynamic> data) async {
    final fingerprint = _encryptionFingerprint(data);
    final cached = _decryptionCache[docId];
    if (cached != null && cached.fingerprint == fingerprint) {
      return cached.text;
    }

    final text = await _decryptChatMessage(data);
    _decryptionCache[docId] = _DecryptionCacheEntry(fingerprint, text);
    return text;
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

  /// Edge users eligible for group invites (logged in at least once).
  Future<List<Map<String, dynamic>>> listGroupEligibleUsers() async {
    List<Map<String, dynamic>> users = [];

    try {
      final snap = await _firestore
          .collection('usernames')
          .where(
            'lastSeen',
            isGreaterThan: Timestamp.fromDate(DateTime(2020, 1, 1)),
          )
          .limit(150)
          .get();
      users = _mapGroupUserDocs(snap.docs);
    } catch (e) {
      debugPrint('ChatService: group users query failed: $e');
    }

    if (users.isEmpty) {
      try {
        final snap = await _firestore.collection('usernames').limit(150).get();
        users = _mapGroupUserDocs(snap.docs);
      } catch (e) {
        debugPrint('ChatService: group users fallback failed: $e');
      }
    }

    users.sort(
      (a, b) => (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase()),
    );
    return users;
  }

  List<Map<String, dynamic>> _mapGroupUserDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          final userId = data['userId'] as String? ?? '';
          if (userId.isEmpty || userId == currentUserId) return null;
          final name = (data['name'] as String? ?? doc.id).trim();
          return {
            'id': userId,
            'userId': userId,
            'username': doc.id,
            'name': name.isEmpty ? doc.id : name,
            'email': data['email'] ?? '',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Get a paginated list of users, filtering out those without a public key
  Future<Map<String, dynamic>> getUsersPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? searchQuery,
  }) async {
    try {
      return await _getUsersPaginatedIndexed(
        lastDocument: lastDocument,
        limit: limit,
        searchQuery: searchQuery,
      );
    } catch (e) {
      debugPrint('ChatService: indexed user query failed, using fallback: $e');
      return _getUsersPaginatedSimple(
        lastDocument: lastDocument,
        limit: limit,
        searchQuery: searchQuery,
      );
    }
  }

  Future<Map<String, dynamic>> _getUsersPaginatedIndexed({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? searchQuery,
  }) async {
    Query query = _firestore.collection('usernames');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      query = query
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: searchLower)
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$searchLower\uf8ff')
          .orderBy(FieldPath.documentId);
    } else {
      query = query.orderBy('publicKey').orderBy(FieldPath.documentId);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return _mapPaginatedUsers(snapshot.docs, limit);
  }

  Future<Map<String, dynamic>> _getUsersPaginatedSimple({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? searchQuery,
  }) async {
    Query query = _firestore.collection('usernames');
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    query = query.limit(limit);
    final snapshot = await query.get();
    return _mapPaginatedUsers(snapshot.docs, limit, searchQuery: searchQuery);
  }

  Map<String, dynamic> _mapPaginatedUsers(
    List<QueryDocumentSnapshot<Object?>> docs,
    int limit, {
    String? searchQuery,
  }) {
    final users = <Map<String, dynamic>>[];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] == currentUserId) continue;
      if (data['publicKey'] == null) continue;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final username = doc.id.toLowerCase();
        if (!name.contains(q) && !username.contains(q)) continue;
      }
      users.add({
        'id': data['userId'],
        'username': doc.id,
        ...data,
      });
    }
    return {
      'users': users,
      'lastDocument': docs.isNotEmpty ? docs.last : null,
      'hasMore': docs.length == limit,
    };
  }

  /// Get or create a chat ID for two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  /// Mark current user as typing / not typing in a chat.
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {
          currentUserId: isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Typing status update failed: $e');
    }
  }

  /// Emits true while [peerUserId] has typed within the last few seconds.
  Stream<bool> watchPeerTyping(String chatId, String peerUserId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((snap) {
      final typing = snap.data()?['typing'];
      if (typing is! Map) return false;
      final raw = typing[peerUserId];
      if (raw is! Timestamp) return false;
      return DateTime.now().difference(raw.toDate()).inSeconds < 5;
    });
  }

  /// Create a new group chat
  Future<String> createGroupChat(
    String groupName, 
    List<String> memberIds, {
    String? communityId,
    bool isAnnouncementGroup = false,
  }) async {
    final chatId = const Uuid().v4();

    final participants = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    participants.add(currentUserId);

    if (participants.length < 2) {
      throw StateError('Grup için en az bir kişi seçilmeli.');
    }

    await _firestore.collection('chats').doc(chatId).set({
      'isGroup': true,
      'groupName': groupName.trim(),
      'participants': participants,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
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
          'isAnnouncementGroup': data['isAnnouncementGroup'] ?? false,
          'communityId': data['communityId'],
        };
      }).where((chat) {
        if (chat['isAnnouncementGroup'] == true) return false;
        if (chat['communityId'] != null) return false;
        if (chat['isGroup'] == true &&
            (chat['groupName'] as String).trim() == 'Duyurular') {
          return false;
        }
        return chat['isGroup'] == true || chat['otherUserId'].isNotEmpty;
      }).toList();
      
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
          if (!isGroup) {
            await _ensureKeysForDecryption();
          }

          List<Map<String, dynamic>> messages = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            
            String decryptedText = '[Mesaj]';
            
            if (isGroup) {
              // Group messages are not E2EE in this version
              decryptedText = data['text'] ?? '';
            } else {
              try {
                decryptedText = await _decryptChatMessageCached(doc.id, data);
              } catch (e) {
                debugPrint('E2EE: Message decrypt failed: $e');
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

  /// Send a text message (queued — returns immediately, sends in background).
  Future<void> sendMessage(String text, {
    String? receiverId, 
    String? explicitChatId, 
    bool isGroup = false, 
    String type = 'text',
    List<String> groupParticipants = const [],
  }) {
    final completer = Completer<void>();
    _outboundQueue.add(_OutboundMessage(
      text: text,
      receiverId: receiverId,
      explicitChatId: explicitChatId,
      isGroup: isGroup,
      type: type,
      groupParticipants: groupParticipants,
      completer: completer,
    ));
    _processOutboundQueue();
    return completer.future;
  }

  Future<void> _processOutboundQueue() async {
    if (_processingOutboundQueue) return;
    _processingOutboundQueue = true;

    while (_outboundQueue.isNotEmpty) {
      final item = _outboundQueue.removeFirst();
      try {
        await _sendMessageInternal(
          item.text,
          receiverId: item.receiverId,
          explicitChatId: item.explicitChatId,
          isGroup: item.isGroup,
          type: item.type,
          groupParticipants: item.groupParticipants,
        );
        if (!item.completer.isCompleted) item.completer.complete();
      } catch (e, stack) {
        debugPrint('Send queue error: $e\n$stack');
        if (!item.completer.isCompleted) item.completer.completeError(e);
      }
    }

    _processingOutboundQueue = false;
  }

  Future<void> _sendMessageInternal(String text, {
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
      await initializeKeys();
      
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

class _DecryptionCacheEntry {
  final String fingerprint;
  final String text;

  const _DecryptionCacheEntry(this.fingerprint, this.text);
}

class _OutboundMessage {
  final String text;
  final String? receiverId;
  final String? explicitChatId;
  final bool isGroup;
  final String type;
  final List<String> groupParticipants;
  final Completer<void> completer;

  _OutboundMessage({
    required this.text,
    required this.receiverId,
    required this.explicitChatId,
    required this.isGroup,
    required this.type,
    required this.groupParticipants,
    required this.completer,
  });
}

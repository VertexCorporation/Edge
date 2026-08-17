import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/role.dart';
import 'cortex_profile.dart';

class AdminUser {
  final String userId;
  final String name;
  final String email;
  final String role;

  const AdminUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });
}

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AdminUser>> listUsers() async {
    final byUid = <String, AdminUser>{};

    try {
      final snap = await _firestore.collection('users').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        byUid[doc.id] = AdminUser(
          userId: doc.id,
          name: CortexProfile.displayName(
            data,
            fallback: data['email'] as String? ?? doc.id,
          ),
          email: data['email'] as String? ?? '',
          role: UserRole.normalize(data['role'] as String?),
        );
      }
    } catch (e) {
      debugPrint('AdminService: users list failed: $e');
    }

    try {
      final snap = await _firestore.collection('usernames').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        if (userId.isEmpty) continue;
        final existing = byUid[userId];
        final usernameRole = UserRole.normalize(data['role'] as String?);
        byUid[userId] = AdminUser(
          userId: userId,
          name: CortexProfile.displayName(
            data,
            fallback: existing?.name ?? doc.id,
          ),
          email: (data['email'] as String?)?.isNotEmpty == true
              ? data['email'] as String
              : (existing?.email ?? ''),
          role: data.containsKey('role')
              ? usernameRole
              : (existing?.role ?? usernameRole),
        );
      }
    } catch (e) {
      debugPrint('AdminService: usernames list failed: $e');
    }

    final users = byUid.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Future<void> assignRole({
    required String email,
    required String role,
    String? userId,
  }) async {
    final normalizedRole = UserRole.normalize(role);
    if (!UserRole.assignableByAdmin.contains(normalizedRole)) {
      throw ArgumentError('Bu rol atanamaz: $role');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty && (userId == null || userId.isEmpty)) {
      throw ArgumentError('E-posta gerekli.');
    }

    try {
      await FirebaseFunctions.instance.httpsCallable('assignUserRole').call({
        if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
        'role': normalizedRole,
        if (userId != null && userId.isNotEmpty) 'uid': userId,
      });
      try {
        await _writeRoleToFirestore(
          email: normalizedEmail,
          role: normalizedRole,
          userId: userId,
        );
      } catch (e) {
        debugPrint('Role Firestore sync after CF: $e');
      }
      return;
    } catch (e) {
      debugPrint('assignUserRole CF failed, using Firestore: $e');
    }

    await _writeRoleToFirestore(
      email: normalizedEmail,
      role: normalizedRole,
      userId: userId,
    );
  }

  Future<void> _writeRoleToFirestore({
    required String email,
    required String role,
    String? userId,
  }) async {
    String? uid = (userId != null && userId.isNotEmpty) ? userId : null;

    if (uid != null) {
      final existing = await _firestore.collection('users').doc(uid).get();
      if (!existing.exists && email.isNotEmpty) {
        uid = null;
      }
    }

    if (uid == null && email.isNotEmpty) {
      final byUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (byUser.docs.isNotEmpty) {
        uid = byUser.docs.first.id;
      }
    }

    if (uid == null) {
      try {
        final usersSnap = await _firestore.collection('users').get();
        for (final doc in usersSnap.docs) {
          final docEmail =
              (doc.data()['email'] as String? ?? '').trim().toLowerCase();
          if (email.isNotEmpty && docEmail == email) {
            uid = doc.id;
            break;
          }
        }
      } catch (e) {
        debugPrint('AdminService: users scan failed: $e');
      }
    }

    if (uid == null && email.isNotEmpty) {
      final byUsername = await _firestore
          .collection('usernames')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (byUsername.docs.isNotEmpty) {
        uid = byUsername.docs.first.data()['userId'] as String?;
      }
    }

    if (uid == null || uid.isEmpty) {
      uid = userId;
    }
    if (uid == null || uid.isEmpty) {
      throw StateError('Kullanıcı bulunamadı.');
    }

    try {
      await _firestore.collection('users').doc(uid).set(
        {'role': role},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('AdminService: users role write failed: $e');
    }

    try {
      final usernameSnap = await _firestore.collection('usernames').get();
      for (final doc in usernameSnap.docs) {
        final data = doc.data();
        final docUid = data['userId'] as String? ?? '';
        final docEmail =
            (data['email'] as String? ?? '').trim().toLowerCase();
        if (docUid == uid || (email.isNotEmpty && docEmail == email)) {
          await doc.reference.set({'role': role}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('AdminService: usernames role write failed: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/role.dart';

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
    List<AdminUser> users = [];

    try {
      final snap = await _firestore.collection('usernames').get();
      users = _mapUserDocs(snap.docs);
    } catch (e) {
      debugPrint('AdminService: usernames list failed: $e');
    }

    if (users.isEmpty) {
      try {
        final snap = await _firestore.collection('users').get();
        users = snap.docs.map((doc) {
          final data = doc.data();
          return AdminUser(
            userId: doc.id,
            name: data['name'] as String? ??
                data['email'] as String? ??
                doc.id,
            email: data['email'] as String? ?? '',
            role: UserRole.normalize(data['role'] as String?),
          );
        }).toList();
      } catch (e) {
        debugPrint('AdminService: users list failed: $e');
      }
    }

    users.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return users;
  }

  List<AdminUser> _mapUserDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          final userId = data['userId'] as String? ?? '';
          if (userId.isEmpty) return null;
          return AdminUser(
            userId: userId,
            name: data['name'] as String? ?? doc.id,
            email: data['email'] as String? ?? '',
            role: UserRole.normalize(data['role'] as String?),
          );
        })
        .whereType<AdminUser>()
        .toList();
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
      throw StateError('Kullanıcı bulunamadı.');
    }

    await _firestore.collection('users').doc(uid).set(
      {'role': role},
      SetOptions(merge: true),
    );

    final usernameSnap = await _firestore
        .collection('usernames')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (usernameSnap.docs.isNotEmpty) {
      await usernameSnap.docs.first.reference.set(
        {'role': role},
        SetOptions(merge: true),
      );
    }
  }
}

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
  }) async {
    final normalizedRole = UserRole.normalize(role);
    if (!UserRole.assignableByAdmin.contains(normalizedRole)) {
      throw ArgumentError('Bu rol atanamaz: $role');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError('E-posta gerekli.');
    }

    await FirebaseFunctions.instance.httpsCallable('assignUserRole').call({
      'email': normalizedEmail,
      'role': normalizedRole,
    });
  }
}

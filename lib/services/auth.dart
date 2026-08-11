import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Authentication service for Vertex Edge
/// Handles Firebase Auth + Firestore isVertex verification
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail if unable to update status
      }
    }
  }

  /// Sign in with email and password, then verify isVertex
  /// Returns a result with user data or error message
  Future<AuthResult> signIn(String email, String password) async {
    try {
      // 1. Authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.error('Giriş başarısız. Lütfen tekrar deneyin.');
      }

      // 2. Get user profile data
      final userData = await getUserData(user.uid);

      return AuthResult.success(
        user: user,
        name: userData?['name'] ?? user.displayName ?? 'Vertex Üyesi',
        role: userData?['role'] ?? 'Üye',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Create a new user with email and password
  Future<AuthResult> createUser(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.error('Kayıt başarısız. Lütfen tekrar deneyin.');
      }

      await user.updateDisplayName(name);

      // Create user document
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email.trim(),
        'role': 'Üye',
        'isVertex': false,
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return AuthResult.success(
        user: user,
        name: name,
        role: 'Üye',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Check if user has isVertex: true in Firestore or is an admin
  Future<bool> checkIsVertex(String uid) async {
    try {
      // First check if user has admin claim
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        final idTokenResult = await user.getIdTokenResult();
        if (idTokenResult.claims?['admin'] == true || 
            idTokenResult.claims?['isAdmin'] == true || 
            idTokenResult.claims?['role'] == 'admin') {
          return true;
        }
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      return data['isVertex'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Convert Firebase Auth error codes to Turkish messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresine sahip bir hesap bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Giriş hatası: $code';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;
  final String? name;
  final String? role;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.name,
    this.role,
  });

  factory AuthResult.success({
    required User user,
    required String name,
    required String role,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      name: name,
      role: role,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

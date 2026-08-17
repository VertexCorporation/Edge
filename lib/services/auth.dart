import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/role.dart';

/// Authentication service for Vertex Edge
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Single shared stream so StreamBuilder rebuilds don't drop the session.
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Keep auth session in browser storage (prevents random web logouts).
  static Future<void> configureWebPersistence() async {
    if (!kIsWeb) return;
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('Auth persistence setup failed: $e');
    }
  }

  /// Completes Google/Apple sign-in after a mobile-web redirect.
  static Future<void> completeWebRedirectSignIn() async {
    if (!kIsWeb) return;
    try {
      await FirebaseAuth.instance.getRedirectResult();
    } catch (e) {
      debugPrint('OAuth redirect result failed: $e');
    }
  }

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
        // Silently fail if unable to update status in users collection
      }

      if (isBootstrapAdminEmail(user.email)) {
        await tryClaimBootstrapAdmin(user);
      }

      final userData = await getUserData(user.uid);
      await _syncUsernameProfile(
        user,
        isOnline: isOnline,
        email: user.email,
        role: userData?['role'] as String?,
      );
    }
  }

  /// Syncs public profile info to the usernames collection
  Future<void> _syncUsernameProfile(User user, {String? name, String? email, String? role, bool isOnline = true}) async {
    try {
      final query = await _firestore.collection('usernames').where('userId', isEqualTo: user.uid).limit(1).get();
      
      if (query.docs.isNotEmpty) {
        final data = <String, dynamic>{
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        };
        if (name != null) data['name'] = name;
        if (email != null) data['email'] = email;
        if (role != null) data['role'] = role;

        final docId = query.docs.first.id;
        await _firestore.collection('usernames').doc(docId).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      // Ignore if it fails
    }
  }

  static const bootstrapAdminEmails = {
    'rel0adneverdone@gmail.com',
    'mustawtfa@gmail.com',
  };

  static bool isBootstrapAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    return normalized != null && bootstrapAdminEmails.contains(normalized);
  }

  /// Bootstrap Yönetici claim for allowlisted emails (server-validated).
  Future<bool> tryClaimBootstrapAdmin(User user) async {
    final email = user.email?.trim().toLowerCase();
    if (email == null || !bootstrapAdminEmails.contains(email)) return false;

    try {
      await FirebaseFunctions.instance
          .httpsCallable('claimBootstrapAdmin')
          .call();
      return true;
    } catch (e) {
      debugPrint('Bootstrap admin CF failed, trying Firestore fallback: $e');
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'role': UserRole.admin},
        SetOptions(merge: true),
      );
      await _syncUsernameProfile(
        user,
        role: UserRole.admin,
        email: email,
      );
      return true;
    } catch (e) {
      debugPrint('Bootstrap admin Firestore fallback failed: $e');
      return false;
    }
  }

  /// Sign in with email and password, then verify isVertex
  /// Returns a result with user data or error message
  Future<AuthResult> signIn(String email, String password) async {
    try {
      // 1. Authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.error('Giriş başarısız. Lütfen tekrar deneyin.');
      }

      // 2. Get user profile data
      await tryClaimBootstrapAdmin(user);
      final userData = await getUserData(user.uid);

      return AuthResult.success(
        user: user,
        name: userData?['name'] ?? user.displayName ?? 'Vertex Üyesi',
        role: UserRole.normalize(userData?['role'] as String?),
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
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.error('Kayıt başarısız. Lütfen tekrar deneyin.');
      }

      await user.updateDisplayName(name);

      final emailNormalized = email.trim().toLowerCase();
      final username = _usernameFromEmail(emailNormalized);

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': emailNormalized,
        'role': 'Üye',
        'isVertex': false,
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('usernames').doc(username).set({
        'userId': user.uid,
        'name': name,
        'email': emailNormalized,
        'role': 'Üye',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await tryClaimBootstrapAdmin(user);
      final userData = await getUserData(user.uid);
      return AuthResult.success(
        user: user,
        name: name,
        role: UserRole.normalize(userData?['role'] as String? ?? 'Üye'),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Sign in with Google — always opens the Google account picker.
  Future<AuthResult> signInWithGoogle() async {
    try {
      User? user;

      if (kIsWeb) {
        final authProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..setCustomParameters({'prompt': 'select_account'});
        user = await _webOAuthSignIn(authProvider);
        if (user == null && _auth.currentUser == null) {
          return AuthResult.error('Google girişi iptal edildi.');
        }
        user ??= _auth.currentUser;
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        try {
          await googleSignIn.disconnect();
        } catch (_) {
          await googleSignIn.signOut();
        }
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult.error('Google girişi iptal edildi.');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user == null) {
        return AuthResult.error('Google girişi başarısız.');
      }

      return await _handleOAuthLogin(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Sign in with Apple — opens Apple ID authentication.
  Future<AuthResult> signInWithApple() async {
    try {
      User? user;

      if (kIsWeb) {
        final authProvider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name')
          ..setCustomParameters({'locale': 'tr_TR'});
        user = await _webOAuthSignIn(authProvider);
        if (user == null && _auth.currentUser == null) {
          return AuthResult.error('Apple girişi iptal edildi.');
        }
        user ??= _auth.currentUser;
      } else {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final credential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;

        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final name =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
          if (name.isNotEmpty) {
            await user?.updateDisplayName(name);
          }
        }
      }

      if (user == null) {
        return AuthResult.error('Apple girişi başarısız.');
      }

      return await _handleOAuthLogin(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.error('Apple girişi iptal edildi.');
      }
      return AuthResult.error('Apple girişi başarısız.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Popup first; if the browser blocks it (common on mobile web), redirect.
  Future<User?> _webOAuthSignIn(AuthProvider provider) async {
    try {
      final credential = await _auth.signInWithPopup(provider);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      if (e.code == 'popup-blocked' ||
          e.code == 'operation-not-supported-in-this-environment') {
        await _auth.signInWithRedirect(provider);
        return null;
      }
      rethrow;
    }
  }

  Future<AuthResult> _handleOAuthLogin(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    String name = user.displayName ?? 'Kullanıcı';

    if (doc.exists) {
      name = doc.data()?['name'] ?? name;
      await updateOnlineStatus(true);
    } else {
      if (user.displayName == null || user.displayName!.isEmpty) {
        await user.updateDisplayName(name);
      }
    }

    await tryClaimBootstrapAdmin(user);
    final refreshed = await getUserData(user.uid);
    final effectiveName = refreshed?['name'] as String? ?? name;
    final effectiveRole = UserRole.normalize(refreshed?['role'] as String?);

    await _syncUsernameProfile(
      user,
      name: effectiveName,
      email: user.email ?? '',
      role: effectiveRole,
      isOnline: true,
    );

    return AuthResult.success(
      user: user,
      name: effectiveName,
      role: effectiveRole,
    );
  }

  /// Check if user has isVertex: true in Firestore or is an admin
  Future<bool> checkIsVertex(String uid) async {
    // First check if user has admin claim
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        final idTokenResult = await user.getIdTokenResult();
        if (idTokenResult.claims?['admin'] == true || 
            idTokenResult.claims?['isAdmin'] == true || 
            idTokenResult.claims?['role'] == 'admin') {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking admin claims: $e');
    }

    // Retry logic to handle Cloud Function delay and WebChannel errors
    int retries = 4;
    while (retries > 0) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['isVertex'] == true) {
            return true;
          }
          // If document exists but isVertex is not true, we can definitively return false
          if (data != null && data.containsKey('isVertex')) {
            return false;
          }
        }
        
        // If document doesn't exist yet, wait and retry (Cloud Function might be running)
        retries--;
        if (retries > 0) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        debugPrint('Error checking isVertex (Retries left: $retries): $e');
        retries--;
        if (retries > 0) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    return false;
  }

  String _usernameFromEmail(String email) {
    final localPart = email.split('@').first.toLowerCase();
    final sanitized = localPart.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return sanitized.isNotEmpty ? sanitized : 'user';
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      final normalized = Map<String, dynamic>.from(data);
      if (normalized['role'] != null) {
        normalized['role'] = UserRole.normalize(normalized['role'] as String?);
      }
      return normalized;
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (e) {
      debugPrint('Google sign out failed: $e');
    }
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
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Giriş iptal edildi.';
      case 'popup-blocked':
        return 'Tarayıcı pop-up penceresini engelledi. Lütfen tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi henüz etkin değil.';
      case 'unauthorized-domain':
        return 'Bu domain için Google/Apple girişi yetkili değil.';
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

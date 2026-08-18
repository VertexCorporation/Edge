import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/role.dart';
import '../utils/ios.dart';
import 'cortex_profile.dart';

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

  /// Completes Google/Apple sign-in after a full-page OAuth redirect.
  static Future<void> completeWebRedirectSignIn() async {
    if (!kIsWeb) return;
    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      final user = result.user;
      if (user != null) {
        await AuthService()._handleOAuthLogin(user);
      }
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
          'isEdge': true,
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail if unable to update status in users collection
      }

      if (isBootstrapAdminEmail(user.email)) {
        await tryClaimBootstrapAdmin(user);
      }

      if (isOnline) {
        final linked = await _linkCortexProfile(user);
        if (linked == null) {
          await _syncUsernameProfile(
            user,
            isOnline: true,
            email: user.email,
          );
        }
      } else {
        final userData = await getUserData(user.uid);
        await _syncUsernameProfile(
          user,
          isOnline: false,
          email: user.email,
          role: userData?['role'] as String?,
        );
      }
    }
  }

  /// Syncs public profile info to the usernames collection
  Future<void> _syncUsernameProfile(User user, {String? name, String? email, String? role, bool isOnline = true}) async {
    try {
      final query = await _firestore.collection('usernames').where('userId', isEqualTo: user.uid).limit(1).get();
      
      if (query.docs.isNotEmpty) {
        final data = <String, dynamic>{
          'isOnline': isOnline,
          'isEdge': true,
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
      await restoreBootstrapAdmins();
      return true;
    } catch (e) {
      debugPrint('Bootstrap admin CF failed, trying Firestore fallback: $e');
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'role': UserRole.admin,
          'isEdge': true,
        },
        SetOptions(merge: true),
      );
      await _syncUsernameProfile(
        user,
        role: UserRole.admin,
        email: email,
      );
      await restoreBootstrapAdmins();
      return true;
    } catch (e) {
      debugPrint('Bootstrap admin Firestore fallback failed: $e');
      return false;
    }
  }

  /// Restores Yönetici on the allowlisted accounts if their user docs exist.
  Future<void> restoreBootstrapAdmins() async {
    for (final email in bootstrapAdminEmails) {
      try {
        final snap = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) continue;
        await snap.docs.first.reference.set({
          'role': UserRole.admin,
          'isEdge': true,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Bootstrap admin restore failed for $email: $e');
      }
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
      Map<String, dynamic>? userData;
      try {
        userData = await _linkCortexProfile(user)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Profile link timed out: $e');
      }
      userData ??= await getUserData(user.uid);

      return AuthResult.success(
        user: user,
        name: CortexProfile.displayName(
          userData,
          fallback: user.displayName ?? 'Vertex Üyesi',
        ),
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
      final existing = await _firestore.collection('users').doc(user.uid).get();
      final existingData = existing.data();

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': emailNormalized,
        if (existingData?['role'] == null) 'role': 'Üye',
        if (!CortexProfile.isRegistered(existingData)) 'isVertex': false,
        'isEdge': true,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _ensureUsernameDoc(
        user,
        name: name,
        email: emailNormalized,
        role: existingData?['role'] as String? ?? 'Üye',
        preferredUsername: CortexProfile.usernameOf(existingData) ?? username,
      );

      await tryClaimBootstrapAdmin(user);
      final userData =
          await _linkCortexProfile(user) ?? await getUserData(user.uid);
      return AuthResult.success(
        user: user,
        name: CortexProfile.displayName(userData, fallback: name),
        role: UserRole.normalize(userData?['role'] as String? ?? 'Üye'),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Sign in with Google — on web, redirects this tab to Google accounts.
  Future<AuthResult> signInWithGoogle() async {
    try {
      User? user;

      if (kIsWeb) {
        final authProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..setCustomParameters({
            'prompt': 'select_account',
            'access_type': 'online',
          });
        await _auth.signInWithRedirect(authProvider);
        return AuthResult.redirecting();
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

  /// Sign in with Apple — iOS only. Web iOS redirects to Apple's account page.
  Future<AuthResult> signInWithApple() async {
    if (!isIosDevice()) {
      return AuthResult.error('CIHAZ IOS DEĞIL');
    }

    try {
      User? user;

      if (kIsWeb) {
        final authProvider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name')
          ..setCustomParameters({'locale': 'tr_TR'});
        await _auth.signInWithRedirect(authProvider);
        return AuthResult.redirecting();
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

  Future<AuthResult> _handleOAuthLogin(User user) async {
    await tryClaimBootstrapAdmin(user);
    final linked = await _linkCortexProfile(user);
    final refreshed = linked ?? await getUserData(user.uid);
    final effectiveName = CortexProfile.displayName(
      refreshed,
      fallback: user.displayName ?? 'Kullanıcı',
    );
    final effectiveRole = UserRole.normalize(refreshed?['role'] as String?);

    if ((user.displayName == null || user.displayName!.isEmpty) &&
        effectiveName.isNotEmpty) {
      await user.updateDisplayName(effectiveName);
    }

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
          if (CortexProfile.isVertexMember(data)) {
            return true;
          }
          if (data != null &&
              data.containsKey('isVertex') &&
              !CortexProfile.isRegistered(data)) {
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

  String _sanitizeUsername(String raw) {
    final sanitized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return sanitized.isNotEmpty ? sanitized : 'user';
  }

  String _usernameFromEmail(String email) {
    return _sanitizeUsername(email.split('@').first);
  }

  /// Pull Cortex `users/{uid}` into Edge without touching Cortex-owned fields.
  Future<Map<String, dynamic>?> _linkCortexProfile(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        final classicName =
            (user.displayName ?? '').trim().isNotEmpty
                ? user.displayName!.trim()
                : 'Kullanıcı';
        final classic = <String, dynamic>{
          'name': classicName,
          'email': user.email ?? '',
          'role': UserRole.member,
          'isVertex': false,
          'isEdge': true,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(
              classic,
              SetOptions(merge: true),
            );
        await _ensureUsernameDoc(
          user,
          name: classicName,
          email: user.email ?? '',
          role: UserRole.member,
        );
        classic['name'] = classicName;
        return classic;
      }
      if (CortexProfile.isAnonymousAccount(data)) return data;

      final displayName = CortexProfile.displayName(
        data,
        fallback: user.displayName,
      );
      final edgeFields = <String, dynamic>{
        'isOnline': true,
        'isEdge': true,
        'lastSeen': FieldValue.serverTimestamp(),
      };
      if ((data['name'] as String?)?.trim().isEmpty ?? true) {
        edgeFields['name'] = displayName;
      }
      if (CortexProfile.isRegistered(data) && data['isVertex'] != true) {
        edgeFields['isVertex'] = true;
      }
      if (data['role'] == null) {
        edgeFields['role'] = UserRole.member;
      }

      await _firestore.collection('users').doc(user.uid).set(
            edgeFields,
            SetOptions(merge: true),
          );

      await _ensureUsernameDoc(
        user,
        name: displayName,
        email: user.email ?? (data['email'] as String? ?? ''),
        role: UserRole.normalize(data['role'] as String?),
        preferredUsername: CortexProfile.usernameOf(data),
      );

      final merged = Map<String, dynamic>.from(data)..addAll(edgeFields);
      merged['name'] = displayName;
      if (CortexProfile.isRegistered(data)) {
        merged['isVertex'] = true;
      }
      if (merged['role'] != null) {
        merged['role'] = UserRole.normalize(merged['role'] as String?);
      }
      return merged;
    } catch (e) {
      debugPrint('Cortex profile link failed: $e');
      return null;
    }
  }

  Future<void> _ensureUsernameDoc(
    User user, {
    required String name,
    required String email,
    String? role,
    String? preferredUsername,
  }) async {
    try {
      final query = await _firestore
          .collection('usernames')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        await _syncUsernameProfile(
          user,
          name: name,
          email: email,
          role: role,
          isOnline: true,
        );
        return;
      }

      final base = _sanitizeUsername(
        (preferredUsername != null && preferredUsername.isNotEmpty)
            ? preferredUsername
            : _usernameFromEmail(email),
      );
      var docId = base;
      var suffix = 1;
      while (true) {
        final ref = _firestore.collection('usernames').doc(docId);
        final existing = await ref.get();
        if (!existing.exists || existing.data()?['userId'] == user.uid) {
          await ref.set({
            'userId': user.uid,
            'name': name,
            if (email.isNotEmpty) 'email': email,
            if (role != null) 'role': role,
            'isOnline': true,
            'isEdge': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return;
        }
        docId = '$base$suffix';
        suffix++;
      }
    } catch (e) {
      debugPrint('Username profile ensure failed: $e');
    }
  }

  /// Live profile so role changes show without re-login.
  /// Merges `users` and `usernames` because role is often written to usernames first.
  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    final controller = StreamController<Map<String, dynamic>?>.broadcast();
    Map<String, dynamic>? userData;
    Map<String, dynamic>? usernameData;
    var userReady = false;
    var usernameReady = false;

    void emit() {
      if (controller.isClosed || !userReady || !usernameReady) return;
      if (userData == null && usernameData == null) {
        controller.add(null);
        return;
      }
      final merged = <String, dynamic>{
        ...?usernameData,
        ...?userData,
      };
      merged['role'] = UserRole.normalize(
        usernameData?['role'] as String? ?? userData?['role'] as String?,
      );
      merged['name'] = CortexProfile.displayName(merged);
      merged['isVertex'] = CortexProfile.isVertexMember(userData ?? merged);
      controller.add(merged);
    }

    final userSub = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      userData = doc.data();
      userReady = true;
      emit();
    });
    final usernameSub = _firestore
        .collection('usernames')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .listen((snap) {
      usernameData = snap.docs.isEmpty ? null : snap.docs.first.data();
      usernameReady = true;
      emit();
    });

    controller.onCancel = () {
      userSub.cancel();
      usernameSub.cancel();
    };
    return controller.stream.distinct((prev, next) {
      return prev?['role'] == next?['role'] &&
          prev?['name'] == next?['name'] &&
          prev?['isVertex'] == next?['isVertex'];
    });
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
      normalized['name'] = CortexProfile.displayName(normalized);
      if (CortexProfile.isRegistered(normalized)) {
        normalized['isVertex'] = true;
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

  factory AuthResult.redirecting() {
    return AuthResult._(isSuccess: true);
  }

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

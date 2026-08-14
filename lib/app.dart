import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';
import 'screens/login.dart';
import 'screens/home_shell.dart';
import 'models/role.dart';
import 'services/auth.dart';
import 'services/chat.dart';
import 'services/notification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Root application widget
/// Handles authentication state and routing
class EdgeApp extends StatefulWidget {
  const EdgeApp({super.key});

  @override
  State<EdgeApp> createState() => _EdgeAppState();
}

class _EdgeAppState extends State<EdgeApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  /// Prevents login-screen flash when auth stream briefly resets on rebuild.
  User? _stableUser;
  Future<Map<String, dynamic>?>? _userDataFuture;
  String? _userDataUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        if (kIsWeb) {
          NotificationService().initialize().catchError((_) {});
        } else {
          NotificationService().saveDeviceToken();
        }
        _authService.updateOnlineStatus(true);
        ChatService().initializeKeys().catchError((_) {});
        _authService.tryClaimBootstrapAdmin(user).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authService.updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _authService.updateOnlineStatus(false);
    }
  }

  Future<Map<String, dynamic>?> _userDataFor(String uid) {
    if (_userDataUid == uid && _userDataFuture != null) {
      return _userDataFuture!;
    }
    _userDataUid = uid;
    _userDataFuture = _authService
        .getUserData(uid)
        .timeout(const Duration(seconds: 8), onTimeout: () => null);
    return _userDataFuture!;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final themeColors = AppColors.getThemeColors(AppColors.currentTheme);
    final isDarkUi = themeColors.statusBarIconBrightness == Brightness.light;

    return MaterialApp(
      title: 'Vertex Edge',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkUi ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      home: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // Keep showing home while a new stream subscription is warming up.
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_stableUser != null) {
              return _buildHome(_stableUser!);
            }
            return const _SplashScreen();
          }

          final user = snapshot.data;
          if (user == null) {
            _stableUser = null;
            _userDataFuture = null;
            _userDataUid = null;
            return const LoginScreen();
          }

          _stableUser = user;
          return _buildHome(user);
        },
      ),
    );
  }

  Widget _buildHome(User user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFor(user.uid),
      builder: (context, userDataSnapshot) {
        if (userDataSnapshot.connectionState == ConnectionState.waiting &&
            !userDataSnapshot.hasData) {
          return const _SplashScreen();
        }

        final userData = userDataSnapshot.data;
        final role = UserRole.normalize(
          userData?['role'] as String? ??
              AppLocalizations.of(context)!.member,
        );
        return HomeShell(
          userName: userData?['name'] ??
              user.displayName ??
              AppLocalizations.of(context)!.vertexMember,
          userRole: role,
          userEmail: user.email ?? '',
          isVertex: userData?['isVertex'] == true,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final themeColors = AppColors.getThemeColors(AppColors.currentTheme);
    final isDarkUi = themeColors.statusBarIconBrightness == Brightness.light;
    final surface =
        isDarkUi ? const Color(0xFF0D1B3E) : themeColors.secondaryColor;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: themeColors.background,
      canvasColor: themeColors.background,
      cardColor: surface,
      primaryColor: themeColors.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors.senaryColor,
        brightness: isDarkUi ? Brightness.dark : Brightness.light,
        surface: surface,
      ),
    );
  }
}

/// Splash screen shown during authentication check
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Image.asset(
                'assets/icons/edge/transparent.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.hub_outlined,
                  size: 80,
                  color: AppColors.senaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

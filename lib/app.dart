import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';
import 'screens/login.dart';
import 'screens/chat/list.dart';
import 'services/auth.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        NotificationService().saveDeviceToken();
        _authService.updateOnlineStatus(true);
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
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _authService.updateOnlineStatus(false);
    }
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
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          // Not authenticated - show login
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          // Authenticated - show home directly
          return FutureBuilder<Map<String, dynamic>?>(
            future: _authService.getUserData(snapshot.data!.uid),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const _SplashScreen();
              }

              final userData = userDataSnapshot.data;
              return ChatListScreen(
                userName: userData?['name'] ??
                    snapshot.data?.displayName ??
                    AppLocalizations.of(context)!.vertexMember,
                userRole: userData?['role'] ?? AppLocalizations.of(context)!.member,
                userEmail: snapshot.data?.email ?? '',
                isVertex: userData?['isVertex'] == true,
              );
            },
          ); // Closes FutureBuilder
        },
      ), // Closes StreamBuilder
    ); // Closes MaterialApp
  }

  ThemeData _buildTheme(Brightness brightness) {
    final themeColors = AppColors.getThemeColors(AppColors.currentTheme);
    final isDarkUi = themeColors.statusBarIconBrightness == Brightness.light;
    final surface = isDarkUi ? const Color(0xFF0D1B3E) : themeColors.secondaryColor;

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
            // Logo with Shimmer
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

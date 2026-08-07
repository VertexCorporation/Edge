import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/theme.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'services/auth.dart';

/// Root application widget
/// Handles authentication state and routing
class EdgeApp extends StatefulWidget {
  const EdgeApp({super.key});

  @override
  State<EdgeApp> createState() => _EdgeAppState();
}

class _EdgeAppState extends State<EdgeApp> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertex Edge',
      debugShowCheckedModeBanner: false,
      theme: VertexTheme.light,
      darkTheme: VertexTheme.dark,
      themeMode: ThemeMode.dark, // Default to dark mode (Vertex style)
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

          // Authenticated - verify isVertex and show home
          return FutureBuilder<bool>(
            future: _authService.checkIsVertex(snapshot.data!.uid),
            builder: (context, vertexSnapshot) {
              if (vertexSnapshot.connectionState == ConnectionState.waiting) {
                return const _SplashScreen();
              }

              if (vertexSnapshot.data != true) {
                // Force sign out if not vertex member
                _authService.signOut();
                return const LoginScreen();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _authService.getUserData(snapshot.data!.uid),
                builder: (context, userDataSnapshot) {
                  if (userDataSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _SplashScreen();
                  }

                  final userData = userDataSnapshot.data;
                  return HomeScreen(
                    userName: userData?['name'] ??
                        snapshot.data?.displayName ??
                        'Vertex Üyesi',
                    userRole: userData?['role'] ?? 'Üye',
                    userEmail: snapshot.data?.email ?? '',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Splash screen shown during authentication check
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.hexagon_outlined,
                size: 32,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

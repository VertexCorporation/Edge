import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase.dart';
import 'app.dart';
import 'theme.dart';
import 'services/auth.dart';
import 'services/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw Exception('Firebase başlatılamadı. İnternet bağlantınızı kontrol edin.');
  }

  await AuthService.configureWebPersistence();
  await AuthService.completeWebRedirectSignIn();

  // Push notifications block first paint on mobile web — init after UI on web.
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selectedTheme') ?? 'light';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(savedTheme),
      child: const EdgeApp(),
    ),
  );
}

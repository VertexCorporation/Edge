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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.configureWebPersistence();

  // Initialize notification service
  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selectedTheme') ?? 'light';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(savedTheme),
      child: const EdgeApp(),
    ),
  );
}

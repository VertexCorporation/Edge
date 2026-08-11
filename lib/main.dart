import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase.dart';
import 'app.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EdgeApp());
}

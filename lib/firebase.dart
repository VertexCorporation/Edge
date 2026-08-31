import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the Vertex Edge app.
/// Project: vertex-ai-1618
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return null; // Will use GoogleService-Info.plist natively
      case TargetPlatform.macOS:
        return ios; // fallback to ios config
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia is not supported.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBEp_LYyZWnvdhdJzvRf_h8U6rEEq2Iyp4',
    appId: '1:561391430514:web:5f06c6a84539ecffb10beb',
    messagingSenderId: '561391430514',
    projectId: 'vertex-ai-1618',
    authDomain: 'vertex-ai-1618.firebaseapp.com',
    databaseURL: 'https://vertex-ai-1618-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'vertex-ai-1618.firebasestorage.app',
    measurementId: 'G-G1LJNV60Q3',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBEp_LYyZWnvdhdJzvRf_h8U6rEEq2Iyp4', // Needs a real iOS API Key if restricted
    appId: '1:561391430514:ios:5f06c6a84539ecffb10beb', // Fake structural ID to prevent native crash
    messagingSenderId: '561391430514',
    projectId: 'vertex-ai-1618',
    databaseURL: 'https://vertex-ai-1618-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'vertex-ai-1618.firebasestorage.app',
    iosBundleId: 'com.example.edge',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaNXY_dmb7cV9iFWffX-2B6e13Tbichx0',
    appId: '1:561391430514:android:9bd4d7ef1e5c04f4b10beb',
    messagingSenderId: '561391430514',
    projectId: 'vertex-ai-1618',
    databaseURL: 'https://vertex-ai-1618-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'vertex-ai-1618.firebasestorage.app',
  );
}

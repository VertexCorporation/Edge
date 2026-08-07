import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the Vertex Edge app.
/// Project: vertex-ai-1618
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return web; // Fallback to web config
      case TargetPlatform.iOS:
        return web; // Fallback to web config
      case TargetPlatform.macOS:
        return web; // Fallback to web config
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
}

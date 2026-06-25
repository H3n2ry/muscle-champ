// PLACEHOLDER — rode: dart pub global activate flutterfire_cli && flutterfire configure
// Este arquivo será gerado automaticamente com suas credenciais Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma não suportada');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUBSTITUA',
    appId: 'SUBSTITUA',
    messagingSenderId: 'SUBSTITUA',
    projectId: 'SUBSTITUA',
    storageBucket: 'SUBSTITUA',
    authDomain: 'SUBSTITUA',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUBSTITUA',
    appId: 'SUBSTITUA',
    messagingSenderId: 'SUBSTITUA',
    projectId: 'SUBSTITUA',
    storageBucket: 'SUBSTITUA',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUBSTITUA',
    appId: 'SUBSTITUA',
    messagingSenderId: 'SUBSTITUA',
    projectId: 'SUBSTITUA',
    storageBucket: 'SUBSTITUA',
    iosBundleId: 'SUBSTITUA',
  );
}

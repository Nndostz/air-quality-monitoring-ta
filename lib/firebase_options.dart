// lib/firebase_options.dart
// File ini ganti flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ========== WEB ==========
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCV08jOjFXpF7vaR2uXsttC1T_jE8Py-nI",
    authDomain: "airqualitymonitoring-29268.firebaseapp.com",
    databaseURL:
        "https://airqualitymonitoring-29268-default-rtdb.firebaseio.com",
    projectId: "airqualitymonitoring-29268",
    storageBucket: "airqualitymonitoring-29268.firebasestorage.app",
    messagingSenderId: "863952557052",
    appId: "1:863952557052:web:71a750fd156cb27aca1879",
  );

  // ========== ANDROID ==========
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:android:abcdef',
    messagingSenderId: '123456789',
    projectId: 'project-id',
    databaseURL: 'https://project-id.firebaseio.com',
    storageBucket: 'project-id.appspot.com',
  );

  // ========== iOS ==========
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:ios:abcdef',
    messagingSenderId: '123456789',
    projectId: 'project-id',
    databaseURL: 'https://project-id.firebaseio.com',
    storageBucket: 'project-id.appspot.com',
    iosClientId: 'xxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.airQualityApp',
  );

  // ========== macOS ==========
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:ios:abcdef',
    messagingSenderId: '123456789',
    projectId: 'project-id',
    databaseURL: 'https://project-id.firebaseio.com',
    storageBucket: 'project-id.appspot.com',
    iosClientId: 'xxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.airQualityApp',
  );

  // ========== Windows ==========
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:web:abcdef',
    messagingSenderId: '123456789',
    projectId: 'project-id',
    databaseURL: 'https://project-id.firebaseio.com',
    storageBucket: 'project-id.appspot.com',
  );
}

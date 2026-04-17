import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDy4ZalvB7_7kt_VEJ0cVMljQdhZOeylN0',
    appId: '1:472149507943:web:865f0e5b6b9c2', // Reconstructed
    messagingSenderId: '472149507943',
    projectId: 'habit-tracker-app-53646',
    authDomain: 'habit-tracker-app-53646.firebaseapp.com',
    storageBucket: 'habit-tracker-app-53646.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDy4ZalvB7_7kt_VEJ0cVMljQdhZOeylN0',
    appId: '1:472149507943:android:ef4d674e7f35f0e5b6b9c2',
    messagingSenderId: '472149507943',
    projectId: 'habit-tracker-app-53646',
    storageBucket: 'habit-tracker-app-53646.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDy4ZalvB7_7kt_VEJ0cVMljQdhZOeylN0',
    appId: '1:472149507943:windows:ef4d674e7f35f0e5b6b9c2',
    messagingSenderId: '472149507943',
    projectId: 'habit-tracker-app-53646',
    authDomain: 'habit-tracker-app-53646.firebaseapp.com',
    storageBucket: 'habit-tracker-app-53646.firebasestorage.app',
  );
}

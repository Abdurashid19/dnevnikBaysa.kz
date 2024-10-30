// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBWcK6Al_me5kHe_I9PoB3wuDcUuLX6c3k',
    appId: '1:262630947835:web:a4fb0b2d8d0e04afa0695e',
    messagingSenderId: '262630947835',
    projectId: 'dnevnikbaysa',
    authDomain: 'dnevnikbaysa.firebaseapp.com',
    storageBucket: 'dnevnikbaysa.appspot.com',
    measurementId: 'G-3TKETVL819',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBg42r4Bw2X1Sd7RS6lHHVgKiWF4afXXKY',
    appId: '1:262630947835:android:b2131b6c1a6089bfa0695e',
    messagingSenderId: '262630947835',
    projectId: 'dnevnikbaysa',
    storageBucket: 'dnevnikbaysa.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLNxz7L9XvcBuXRH2km9kovujZ_n5HGXA',
    appId: '1:262630947835:ios:59c1a3a6dcfe6066a0695e',
    messagingSenderId: '262630947835',
    projectId: 'dnevnikbaysa',
    storageBucket: 'dnevnikbaysa.appspot.com',
    iosBundleId: 'kz.mobile.baysa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLNxz7L9XvcBuXRH2km9kovujZ_n5HGXA',
    appId: '1:262630947835:ios:3ea2a53f5330a329a0695e',
    messagingSenderId: '262630947835',
    projectId: 'dnevnikbaysa',
    storageBucket: 'dnevnikbaysa.appspot.com',
    iosBundleId: 'com.example.baysaApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBWcK6Al_me5kHe_I9PoB3wuDcUuLX6c3k',
    appId: '1:262630947835:web:4a6943119901a2efa0695e',
    messagingSenderId: '262630947835',
    projectId: 'dnevnikbaysa',
    authDomain: 'dnevnikbaysa.firebaseapp.com',
    storageBucket: 'dnevnikbaysa.appspot.com',
    measurementId: 'G-WWLWCHWQ0T',
  );
}

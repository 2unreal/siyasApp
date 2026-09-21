import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class ProdFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'ProdFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARMjs-jPLGa27f6hD_OMzIYvPOGRngDvo',
    appId: '1:1090120220974:web:35212b497be57ce09bfabf',
    messagingSenderId: '1090120220974',
    projectId: 'siyasapp-509309',
    authDomain: 'siyasapp-509309.firebaseapp.com',
    storageBucket: 'siyasapp-509309.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAV-AhxVS7fVQuUsLeGwIn3HNRvJqJNqWU',
    appId: '1:1090120220974:android:2d2384c51e4b86839bfabf',
    messagingSenderId: '1090120220974',
    projectId: 'siyasapp-509309',
    storageBucket: 'siyasapp-509309.firebasestorage.app',
  );
}

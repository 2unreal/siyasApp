import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DevFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DevFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHrYs1Z6iXlIICXiipwsLJZTEtR30QA4E',
    appId: '1:171601967308:web:c3185fd63c3ff3c2686a69',
    messagingSenderId: '171601967308',
    projectId: 'siyasapp-dev-509309',
    authDomain: 'siyasapp-dev-509309.firebaseapp.com',
    storageBucket: 'siyasapp-dev-509309.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWrjW82lef23zQaJrMED-rFeG5-NHGhOQ',
    appId: '1:171601967308:android:865089c4de34cee6686a69',
    messagingSenderId: '171601967308',
    projectId: 'siyasapp-dev-509309',
    storageBucket: 'siyasapp-dev-509309.firebasestorage.app',
  );
}

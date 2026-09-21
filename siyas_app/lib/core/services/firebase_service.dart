import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/app_environment.dart';
import '../../firebase_options/firebase_options_dev.dart';
import '../../firebase_options/firebase_options_prod.dart';

class FirebaseService {
  FirebaseService._();

  static late final FirebaseApp app;
  static late final FirebaseFirestore firestore;
  static late final FirebaseAuth auth;
  static late final FirebaseStorage storage;

  /// Initializes Firebase and configures native persistence and services
  static Future<void> initialize(AppEnvironment environment) async {
    AppConfig.initialize(environment);

    final FirebaseOptions options = environment == AppEnvironment.dev
        ? DevFirebaseOptions.currentPlatform
        : ProdFirebaseOptions.currentPlatform;

    if (Firebase.apps.isEmpty) {
      app = await Firebase.initializeApp(
        options: options,
      );
    } else {
      app = Firebase.app();
    }

    firestore = FirebaseFirestore.instanceFor(app: app);
    auth = FirebaseAuth.instanceFor(app: app);
    storage = FirebaseStorage.instanceFor(app: app);

    // Configure Cloud Firestore Native Persistence for Mobile / Tablet
    if (!kIsWeb) {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    debugPrint('Firebase initialized for environment: ${AppConfig.current.appTitle}');
  }
}

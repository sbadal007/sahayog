import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static Future<void> initializeApp() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyChSyYjox31qbqhtYDVb5W7eDsQQAFNrok",
            authDomain: "sahayog-aaf08.firebaseapp.com",
            projectId: "sahayog-aaf08",
            storageBucket: "sahayog-aaf08.firebasestorage.app",
            messagingSenderId: "479996813513",
            appId: "1:479996813513:web:1eede32eead6180953ed18",
          ),
        );
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }
}

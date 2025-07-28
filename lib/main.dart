// filepath: c:\Users\susma\Documents\sahayog\lib\main.dart
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy(); // Removes the # from web URLs
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SahayogApp());
}

class SahayogApp extends StatelessWidget {
  const SahayogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
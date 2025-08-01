import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'services/firebase_service.dart';
import 'services/user_status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await FirebaseService.initializeApp();
  
  // Initialize user status service
  UserStatusService().initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const SahayogApp(),
    ),
  );
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
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
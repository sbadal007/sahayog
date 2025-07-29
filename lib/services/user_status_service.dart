import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusService with WidgetsBindingObserver {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  bool _isInitialized = false;
  String? _currentUserId;

  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _listenToAuthChanges();
      _isInitialized = true;
      debugPrint('UserStatusService: Initialized');
    }
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _setUserOffline();
      _isInitialized = false;
      debugPrint('UserStatusService: Disposed');
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        _currentUserId = user.uid;
        _setUserOnline();
        debugPrint('UserStatusService: User logged in: ${user.uid}');
      } else if (user == null && _currentUserId != null) {
        _setUserOffline();
        _currentUserId = null;
        debugPrint('UserStatusService: User logged out');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('UserStatusService: App lifecycle changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setUserOffline();
        break;
    }
  }

  Future<void> _setUserOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('UserStatusService: User ${user.uid} set to online');
    } catch (e) {
      debugPrint('UserStatusService: Error setting user online: $e');
    }
  }

  Future<void> _setUserOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('UserStatusService: User ${user.uid} set to offline');
    } catch (e) {
      debugPrint('UserStatusService: Error setting user offline: $e');
    }
  }

  Future<void> setUserOfflineOnLogout() async {
    await _setUserOffline();
    _currentUserId = null;
    debugPrint('UserStatusService: User logged out and set offline');
  }

  // Helper method to format last seen time
  static String formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'over a week ago';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserProvider extends ChangeNotifier {
  String? _uid;
  String? _username;
  String? _email;
  String? _role;
  String? _profileImageUrl;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Getters
  String? get uid => _uid;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  String? get profileImageUrl => _profileImageUrl;

  // Setters with notification
  set uid(String? value) {
    if (_uid != value) {
      _uid = value;
      notifyListeners();
    }
  }

  set username(String? value) {
    if (_username != value) {
      _username = value;
      notifyListeners();
    }
  }

  set email(String? value) {
    if (_email != value) {
      _email = value;
      notifyListeners();
    }
  }

  set role(String? value) {
    if (_role != value) {
      _role = value;
      notifyListeners();
    }
  }

  set profileImageUrl(String? value) {
    if (_profileImageUrl != value) {
      _profileImageUrl = value;
      notifyListeners();
    }
  }

  Future<void> loadUserFromFirestore(String uid) async {
    try {
      // Cancel any existing subscription
      _userSubscription?.cancel();
      
      // Listen to real-time updates
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          _uid = uid;
          _username = data['username'];
          _email = data['email'];
          _role = data['role'];
          _profileImageUrl = data['profileImageUrl'];
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void clear() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _uid = null;
    _username = null;
    _email = null;
    _role = null;
    _profileImageUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}

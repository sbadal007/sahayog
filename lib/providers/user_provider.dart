import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserProvider extends ChangeNotifier {
  String? uid;
  String? username;
  String? email;
  String? role;
  String? profileImageUrl;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

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
          this.uid = uid;
          username = data['username'];
          email = data['email'];
          role = data['role'];
          profileImageUrl = data['profileImageUrl'];
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
    uid = null;
    username = null;
    email = null;
    role = null;
    profileImageUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}

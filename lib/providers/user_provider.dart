import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String? uid;
  String? username;
  String? email;
  String? role;

  Future<void> loadUserFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        this.uid = uid;
        username = data['username'];
        email = data['email'];
        role = data['role'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void clear() {
    uid = null;
    username = null;
    email = null;
    role = null;
    notifyListeners();
  }
}

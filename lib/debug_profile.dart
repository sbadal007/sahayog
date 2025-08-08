// Debug utility to check user profile data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugUserProfile {
  static Future<void> checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user');
      return;
    }
    
    print('User ID: ${user.uid}');
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data()!;
      print('User document data:');
      data.forEach((key, value) {
        print('  $key: $value');
      });
      
      final profileImageUrl = data['profileImageUrl'];
      if (profileImageUrl != null) {
        print('Profile image URL found: $profileImageUrl');
      } else {
        print('No profile image URL in document');
      }
    } else {
      print('User document does not exist');
    }
  }
}

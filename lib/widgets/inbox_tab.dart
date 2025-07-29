import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'helper_inbox.dart';
import 'requester_inbox.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view messages'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error loading user data: ${snapshot.error}');
          return const Center(child: Text('Error loading inbox'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User profile not found'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] as String?;

        if (userRole == 'Helper') {
          return HelperInbox(userId: user.uid);
        } else if (userRole == 'Requester') {
          return RequesterInbox(userId: user.uid);
        }

        return const Center(child: Text('Invalid user role'));
      },
    );
  }
}
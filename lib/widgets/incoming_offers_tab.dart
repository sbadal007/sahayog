import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomingOffersTab extends StatelessWidget {
  const IncomingOffersTab({super.key});

  Future<void> _handleOffer(String offerId, String action) async {
    final newStatus = action == 'accept' 
        ? 'accepted_by_requester' 
        : 'rejected';
    
    try {
      final offerRef = FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId);
      
      final offerDoc = await offerRef.get();
      final offerData = offerDoc.data();

      if (offerData?['status'] == 'accepted_by_helper' && action == 'accept') {
        await offerRef.update({'status': 'matched'});
      } else {
        await offerRef.update({'status': newStatus});
      }
    } catch (e) {
      debugPrint('Error updating offer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please login to view offers'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('requesterId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        final offers = snapshot.data?.docs ?? [];

        if (offers.isEmpty) {
          return const Center(child: Text('No pending offers'));
        }

        return ListView.builder(
          itemCount: offers.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final offer = offers[index].data() as Map<String, dynamic>;
            final offerId = offers[index].id;
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(offer['helperName']?[0] ?? '?'),
                ),
                title: Text(offer['helperName'] ?? 'Anonymous'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _handleOffer(offerId, 'accept'),
                      child: const Text('Accept'),
                    ),
                    TextButton(
                      onPressed: () => _handleOffer(offerId, 'reject'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

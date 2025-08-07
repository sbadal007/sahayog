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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(offer['helperName']?[0] ?? '?'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            offer['helperName'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Show alternative price if proposed
                    if (offer['alternativePrice'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.price_change, size: 18, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Proposed Price: Rs. ${(offer['alternativePrice'] as num).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Show custom message if provided
                    if (offer['customMessage'] != null && 
                        (offer['customMessage'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message, size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Personal Message:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer['customMessage'] as String,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleOffer(offerId, 'accept'),
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleOffer(offerId, 'reject'),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

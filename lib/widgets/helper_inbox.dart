import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelperInbox extends StatelessWidget {
  final String userId;

  const HelperInbox({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    debugPrint('HelperInbox: Loading offers for userId: $userId');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('helperId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('HelperInbox error: ${snapshot.error}');
          
          // Handle specific permission errors
          if (snapshot.error.toString().contains('permission-denied')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Restricted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don\'t have permission to view offers.\nPlease sign out and sign in again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                      }
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading offers'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final offers = snapshot.data?.docs ?? [];
        debugPrint('HelperInbox: Found ${offers.length} offers');

        // Sort offers by timestamp in code instead of query
        offers.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (offers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No offers made yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  'Start browsing requests to make your first offer!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: offers.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final offer = offers[index].data() as Map<String, dynamic>;
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('requests')
                  .doc(offer['requestId'])
                  .get(),
              builder: (context, requestSnap) {
                final request = requestSnap.data?.data() as Map<String, dynamic>?;
                final timestamp = offer['createdAt'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat.yMd().add_jm().format(timestamp.toDate())
                    : 'No date';

                return Card(
                  child: ListTile(
                    title: Text(request?['title'] ?? 'Request'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${offer['status']}'),
                        Text('Created: $date'),
                        if (offer['status'] == 'accepted')
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement chat or contact functionality
                            },
                            child: const Text('Contact Requester'),
                          ),
                      ],
                    ),
                    trailing: offer['status'] == 'pending'
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _cancelOffer(context, offers[index].id),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _cancelOffer(BuildContext context, String offerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel offer')),
      );
    }
  }
}

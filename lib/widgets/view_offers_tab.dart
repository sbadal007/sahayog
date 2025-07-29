import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class ViewOffersTab extends StatelessWidget {
  const ViewOffersTab({super.key});

  Future<String> _getHelperUsername(String helperId) async {
    try {
      if (helperId == 'test-helper-user') {
        return 'Test Helper';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(helperId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['username'] as String? ?? 'Unknown Helper';
      }
    } catch (e) {
      debugPrint('ViewOffersTab: Error fetching helper username: $e');
    }
    return 'Unknown Helper';
  }

  Future<void> _makeOffer(BuildContext context, String requestId, String requesterId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final helperId = user?.uid ?? 'test-helper-user';
      
      debugPrint('ViewOffersTab: Making offer with helperId: $helperId');

      // Fetch helper username
      final helperName = await _getHelperUsername(helperId);
      debugPrint('ViewOffersTab: Helper username: $helperName');

      // Check for existing active offer
      final existingOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('helperId', isEqualTo: helperId)
          .where('requestId', isEqualTo: requestId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      if (existingOffers.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have an offer for this request')),
        );
        return;
      }

      debugPrint('ViewOffersTab: Creating offer with helperId: $helperId, requesterId: $requesterId');

      // Create new offer with helper username
      final offerRef = await FirebaseFirestore.instance.collection('offers').add({
        'requestId': requestId,
        'helperId': helperId,
        'helperName': helperName, // Store helper username
        'requesterId': requesterId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ViewOffersTab: Offer created with ID: ${offerRef.id}');

      // Fetch request details for notification
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get();
      
      final requestTitle = requestDoc.data()?['title'] ?? 'your request';
      final requesterUsername = requestDoc.data()?['username'] ?? 'Unknown User';

      // Create notification for requester
      await NotificationService.createNotification(
        userId: requesterId,
        title: 'New Offer Received',
        message: '$helperName is interested in helping with "$requestTitle"',
        type: 'new_offer',
        additionalData: {
          'offerId': offerRef.id,
          'requestId': requestId,
          'helperId': helperId,
          'helperName': helperName,
          'requesterUsername': requesterUsername,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer made successfully!')),
      );
    } catch (e) {
      debugPrint('ViewOffersTab: Error making offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make offer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('status', isEqualTo: 'open') // Only show open requests
              .snapshots(), // Remove orderBy to avoid composite index requirement
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('ViewOffersTab: Error loading requests: ${snapshot.error}');
              return const Center(child: Text('Something went wrong.'));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('No open requests found.'));
            }

            // Sort documents in code instead of query to avoid index requirement
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100), // Add padding for the bottom panel
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'No Title';
                final description = data['description'] ?? 'No Description';
                final price = data['price']?.toString() ?? 'N/A';
                final location = data['location'] ?? 'No Location';
                final timestamp = data['createdAt'] as Timestamp?;
                final requesterId = data['userId'] ?? '';
                final requesterUsername = data['username'] ?? 'Unknown User'; // Get requester username
                
                // TODO: In future, calculate actual distance using user's current location
                // and the request's latitude/longitude coordinates
                final dummyDistance = '${(index + 1) * 0.5}'; // Dummy distance for demonstration
                
                final formattedDate = timestamp != null
                    ? DateFormat.yMd().add_jm().format(timestamp.toDate())
                    : 'No Date';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(title, 
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                )
                              ),
                            ),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue,
                              child: Text(
                                requesterUsername[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By: $requesterUsername',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(description),
                        const SizedBox(height: 8),
                        Text('Location: $location', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _makeOffer(
                                      context,
                                      doc.id,
                                      requesterId,
                                    ),
                                    child: const Text('Interested'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. $price',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '~${dummyDistance}km away',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12
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
        ),
        if (FirebaseAuth.instance.currentUser != null || true) // Allow test user
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('helperId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'test-helper-user')
                  .where('status', whereIn: ['pending', 'accepted'])
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final offerDoc = snapshot.data!.docs.first;
                final offerData = offerDoc.data() as Map<String, dynamic>;

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Current Offer',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Status: ${offerData['status']}'),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _cancelOffer(context, offerDoc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _cancelOffer(BuildContext context, String offerId) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(offerId).delete();
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

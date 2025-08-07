import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rating_service.dart';
import '../widgets/rating_dialog.dart';

class HelperInbox extends StatefulWidget {
  final String userId;

  const HelperInbox({super.key, required this.userId});

  @override
  State<HelperInbox> createState() => _HelperInboxState();
}

class _HelperInboxState extends State<HelperInbox> {

  @override
  Widget build(BuildContext context) {
    debugPrint('HelperInbox: Loading offers for userId: ${widget.userId}');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('helperId', isEqualTo: widget.userId)
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
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request?['title'] ?? 'Request',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${offer['status']}'),
                        Text('Created: $date'),
                        
                        // Show original request price if available
                        if (request?['price'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Requested Price: Rs. ${request!['price']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        
                        // Show alternative price if proposed
                        if (offer['alternativePrice'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.price_change, size: 16, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'You proposed: Rs. ${(offer['alternativePrice'] as num).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Show custom message if provided
                        if (offer['customMessage'] != null && 
                            (offer['customMessage'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
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
                                    Icon(Icons.message, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your message:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  offer['customMessage'] as String,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Action buttons
                        Row(
                          children: [
                            if (offer['status'] == 'accepted') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showRatingDialog(
                                    context,
                                    offers[index].id,
                                    offer['requestId'] ?? '',
                                    offer['requesterId'] ?? '',
                                    request?['title'] ?? 'Unknown Request',
                                  ),
                                  icon: const Icon(Icons.star_rate),
                                  label: const Text('Rate Requester'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement chat or contact functionality
                                  },
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Contact'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (offer['status'] == 'pending') ...[
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _cancelOffer(context, offers[index].id),
                                tooltip: 'Cancel Offer',
                              ),
                            ],
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

  Future<void> _showRatingDialog(
    BuildContext context,
    String offerId,
    String requestId,
    String requesterId,
    String requestTitle,
  ) async {
    try {
      // Check if user can rate (hasn't rated already)
      final canRate = await RatingService.canUserRate(
        requestId: requestId,
        reviewerId: widget.userId,
        revieweeId: requesterId,
      );

      if (!canRate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already rated this requester')),
          );
        }
        return;
      }

      // Get requester name
      final requesterDoc = await FirebaseFirestore.instance.collection('users').doc(requesterId).get();
      final requesterName = requesterDoc.data()?['username'] ?? 'Anonymous Requester';

      if (!mounted) return;

      // Show rating dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return RatingDialog(
            requestTitle: requestTitle,
            revieweeName: requesterName,
            reviewType: 'helper_to_requester',
            onCancel: () {
              Navigator.of(dialogContext).pop();
            },
            onSubmit: (double rating, String? review) async {
              Navigator.of(dialogContext).pop();
              await _submitRating(
                offerId: offerId,
                requestId: requestId,
                revieweeId: requesterId,
                revieweeName: requesterName,
                rating: rating,
                review: review,
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing rating dialog: $e');
    }
  }

  Future<void> _submitRating({
    required String offerId,
    required String requestId,
    required String revieweeId,
    required String revieweeName,
    required double rating,
    String? review,
  }) async {
    try {
      // Get current user's name
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final userName = userDoc.data()?['username'] ?? 'Anonymous User';

      await RatingService.createRating(
        requestId: requestId,
        offerId: offerId,
        reviewerId: widget.userId,
        revieweeId: revieweeId,
        reviewerName: userName,
        revieweeName: revieweeName,
        rating: rating,
        review: review,
        reviewType: 'helper_to_requester',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

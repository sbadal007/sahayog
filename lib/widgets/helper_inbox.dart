import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rating_service.dart';
import '../services/chat_service.dart';
import '../widgets/rating_dialog.dart';
import '../screens/chat_screen.dart';

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
                    // Use post-frame callback to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
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
            final offerDoc = offers[index];
            final offer = offerDoc.data() as Map<String, dynamic>;
            // Add the document ID to the offer data for chat functionality
            offer['id'] = offerDoc.id;
            
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (offer['status'] == 'accepted') ...[
                              Row(
                                children: [
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
                                      onPressed: () => _openChat(offer, request),
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (offer['status'] == 'pending') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openChat(offer, request),
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[100],
                                        foregroundColor: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _cancelOffer(context, offers[index].id),
                                    tooltip: 'Cancel Offer',
                                  ),
                                ],
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

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!mounted) return; // Check if widget is still mounted
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    } catch (e) {
      // Ignore errors if widget is disposed
      debugPrint('Error showing SnackBar: $e');
    }
  }

  Future<void> _cancelOffer(BuildContext context, String offerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .delete();
      
      _showSnackBar(context, 'Offer cancelled');
    } catch (e) {
      _showSnackBar(context, 'Failed to cancel offer', isError: true);
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
        _showSnackBar(context, 'You have already rated this requester', isError: true);
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

      _showSnackBar(context, 'Rating submitted successfully!');
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      _showSnackBar(context, 'Failed to submit rating: ${e.toString()}', isError: true);
    }
  }

  Future<void> _openChat(Map<String, dynamic> offer, Map<String, dynamic>? request) async {
    try {
      final offerId = offer['id'] ?? '';
      final requesterId = offer['requesterId'] ?? '';
      final requestId = offer['requestId'] ?? '';
      final requesterName = request?['username'] ?? 'Requester';
      
      if (offerId.isEmpty || requesterId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open chat: Invalid offer data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create or get conversation
      final conversationId = await ChatService.createOrGetConversation(
        offerId: offerId,
        requesterId: requesterId,
        helperId: widget.userId,
        requestId: requestId.isEmpty ? null : requestId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherParticipantName: requesterName,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to open chat: $e', isError: true);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../widgets/offer_dialog.dart';
import '../widgets/user_status_widget.dart';
import '../screens/chat_screen.dart';

class ViewOffersTab extends StatefulWidget {
  const ViewOffersTab({super.key});

  @override
  State<ViewOffersTab> createState() => _ViewOffersTabState();
}

class _ViewOffersTabState extends State<ViewOffersTab> {
  bool _isRetrying = false;
  final Map<String, bool> _loadingStates = {}; // Track loading for individual operations

  Future<void> _refreshRequests() async {
    setState(() {
      _isRetrying = true;
    });
    
    try {
      // Force refresh by triggering a rebuild
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('ViewOffersTab: Error refreshing requests: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _showRequestDetails(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Untitled Request';
    final description = data['description']?.toString() ?? 'No description provided';
    final price = data['price']?.toString() ?? 'Not specified';
    final location = data['location']?.toString() ?? 'Location not specified';
    final requesterId = data['userId']?.toString() ?? '';
    final requesterUsername = data['username']?.toString() ?? 'Anonymous User';
    final timestamp = data['createdAt'] as Timestamp?;
    
    // Get all offers for this request to count interested helpers
    final offersSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('requestId', isEqualTo: doc.id)
        .get();
    
    final interestedCount = offersSnapshot.docs.length;
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasCurrentUserOffer = offersSnapshot.docs.any(
      (offer) => (offer.data()['helperId'] as String?) == currentUser?.uid
    );
    
    final formattedDate = timestamp != null
        ? DateFormat.yMd().add_jm().format(timestamp.toDate())
        : 'Date unknown';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Requester info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Text(
                            requesterUsername.isNotEmpty ? requesterUsername[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requesterUsername,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (requesterId.isNotEmpty)
                                UserStatusWidget(
                                  userId: requesterId,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  showDot: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Interest indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: interestedCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: interestedCount > 0 ? Colors.orange.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            interestedCount > 0 ? Icons.people : Icons.person_add,
                            color: interestedCount > 0 ? Colors.orange.shade600 : Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              interestedCount == 0
                                  ? 'Be the first to show interest!'
                                  : interestedCount == 1
                                      ? '1 helper is interested'
                                      : '$interestedCount helpers are interested',
                              style: TextStyle(
                                color: interestedCount > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.location_on, 'Location', location),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.attach_money, 'Price', 'Rs. $price'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.access_time, 'Posted', formattedDate),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasCurrentUserOffer
                            ? null
                            : () {
                                Navigator.pop(context);
                                _makeOffer(context, doc.id, requesterId);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: hasCurrentUserOffer ? Colors.grey : Colors.blue,
                        ),
                        child: Text(
                          hasCurrentUserOffer
                              ? 'Already Interested'
                              : 'Show Interest',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getHelperUsername(String helperId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(helperId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['username'] != null) {
          return userData['username'] as String;
        }
      }
    } catch (e) {
      debugPrint('ViewOffersTab: Error fetching helper username: $e');
      // Return a fallback instead of throwing
    }
    return 'Helper User'; // Better fallback than 'Unknown Helper'
  }

  Future<Map<String, dynamic>?> _getRequestDetails(String requestId) async {
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get();
      
      if (requestDoc.exists) {
        final data = requestDoc.data();
        // Validate essential fields exist
        if (data != null && data['title'] != null) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('ViewOffersTab: Error fetching request details: $e');
    }
    return null;
  }

  Future<void> _makeOffer(BuildContext context, String requestId, String requesterId) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Enhanced authentication check
    if (user == null) {
      _showErrorSnackBar(
        context, 
        'Authentication required', 
        'Please sign in to make an offer', 
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            // Navigate to sign in screen
            debugPrint('Navigate to sign in');
          },
        ),
      );
      return;
    }

    // Validate input parameters
    if (requestId.isEmpty || requesterId.isEmpty) {
      _showErrorSnackBar(context, 'Invalid request', 'Unable to process this request. Please try again.');
      return;
    }

    try {
      // Check for existing active offer first
      final existingOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('helperId', isEqualTo: user.uid)
          .where('requestId', isEqualTo: requestId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timed out. Please check your connection.'),
          );

      if (existingOffers.docs.isNotEmpty) {
        _showErrorSnackBar(context, 'Duplicate offer', 'You already have an active offer for this request');
        return;
      }

      // Fetch request details to get the title and price for the dialog
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      final requestData = requestDoc.data();
      final requestTitle = requestData?['title'] ?? 'Unknown Request';
      final originalPrice = (requestData?['price'] as num?)?.toDouble() ?? 0.0;

      if (!context.mounted) return;

      // Show the offer dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return OfferDialog(
            requestTitle: requestTitle,
            originalPrice: originalPrice,
            onCancel: () {
              Navigator.of(dialogContext).pop();
            },
            onSubmit: (String? customMessage, double? alternativePrice) async {
              Navigator.of(dialogContext).pop();
              await _createOfferWithDetails(
                context,
                requestId,
                requesterId,
                requestTitle,
                customMessage,
                alternativePrice,
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('ViewOffersTab: Error in _makeOffer: $e');
      _showErrorSnackBar(context, 'Error', 'Failed to load request details. Please try again.');
    }
  }

  Future<void> _createOfferWithDetails(
    BuildContext context,
    String requestId,
    String requesterId,
    String requestTitle,
    String? customMessage,
    double? alternativePrice,
  ) async {
    // Show loading state for this specific offer
    setState(() {
      _loadingStates[requestId] = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final helperId = user.uid;
      
      debugPrint('ViewOffersTab: Creating offer with helperId: $helperId, requesterId: $requesterId');

      // Fetch helper username with error handling
      final helperName = await _getHelperUsername(helperId);
      debugPrint('ViewOffersTab: Helper username: $helperName');

      // Create the offer data
      Map<String, dynamic> offerData = {
        'requestId': requestId,
        'helperId': helperId,
        'helperName': helperName,
        'requesterId': requesterId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields if provided
      if (customMessage != null && customMessage.isNotEmpty) {
        offerData['customMessage'] = customMessage;
      }
      if (alternativePrice != null) {
        offerData['alternativePrice'] = alternativePrice;
      }

      // Create new offer with validation
      final offerRef = await FirebaseFirestore.instance.collection('offers').add(offerData).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Failed to create offer. Please try again.'),
      );

      debugPrint('ViewOffersTab: Offer created with ID: ${offerRef.id}');

      // Get requester username for notification
      final requesterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      final requesterUsername = requesterDoc.data()?['username'] ?? 'Unknown User';

      // Create notification message
      String notificationMessage = '$helperName is interested in helping with "$requestTitle"';
      if (alternativePrice != null) {
        notificationMessage += ' and proposed Rs. ${alternativePrice.toStringAsFixed(0)}';
      }
      if (customMessage != null && customMessage.isNotEmpty) {
        notificationMessage += ' with a custom message';
      }

      // Create notification with error handling (don't fail the whole operation if this fails)
      try {
        await NotificationService.createNotification(
          userId: requesterId,
          title: 'New Offer Received',
          message: notificationMessage,
          type: 'new_offer',
          additionalData: {
            'offerId': offerRef.id,
            'requestId': requestId,
            'helperId': helperId,
            'helperName': helperName,
            'requesterUsername': requesterUsername,
            'hasCustomMessage': customMessage != null && customMessage.isNotEmpty,
            'hasAlternativePrice': alternativePrice != null,
          },
        ).timeout(const Duration(seconds: 10));
      } catch (notificationError) {
        debugPrint('ViewOffersTab: Notification failed (non-critical): $notificationError');
        // Don't fail the whole operation for notification errors
      }

      if (!mounted) return;
      
      // Create chat conversation immediately after offer creation
      String? conversationId;
      try {
        conversationId = await ChatService.createOrGetConversation(
          offerId: offerRef.id,
          requesterId: requesterId,
          helperId: helperId,
          requestId: requestId,
        );
        debugPrint('ViewOffersTab: Chat conversation created: $conversationId');
      } catch (chatError) {
        debugPrint('ViewOffersTab: Chat creation failed (non-critical): $chatError');
        // Don't fail the whole operation for chat creation errors
      }
      
      String successMessage = 'Your offer has been sent successfully';
      if (alternativePrice != null || (customMessage != null && customMessage.isNotEmpty)) {
        successMessage += ' with your custom terms';
      }
      successMessage += '. You can now chat with the requester!';
      
      _showSuccessSnackBar(context, 'Success!', successMessage);
      
      // Show chat navigation option only if conversation was created successfully
      if (mounted && conversationId != null) {
        // Show a SnackBar with chat action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blue.shade600,
            content: const Text('Ready to chat with the requester!'),
            action: SnackBarAction(
              label: 'Open Chat',
              textColor: Colors.white,
              onPressed: () async {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversationId!,
                        otherParticipantName: 'Requester',
                      ),
                    ),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      
    } on FirebaseException catch (e) {
      debugPrint('ViewOffersTab: Firebase error making offer: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to make offer';
      
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'You don\'t have permission to make offers';
          break;
        case 'unavailable':
          errorMessage = 'Service temporarily unavailable. Please try again';
          break;
        case 'deadline-exceeded':
          errorMessage = 'Request timed out. Please check your connection';
          break;
        default:
          errorMessage = 'Network error. Please try again';
      }
      
      _showErrorSnackBar(context, 'Offer failed', errorMessage,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _makeOffer(context, requestId, requesterId),
        ),
      );
    } catch (e) {
      debugPrint('ViewOffersTab: General error making offer: $e');
      String errorMessage = 'An unexpected error occurred';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your connection';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection';
      }
      
      _showErrorSnackBar(context, 'Error', errorMessage,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _makeOffer(context, requestId, requesterId),
        ),
      );
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _loadingStates.remove(requestId);
        });
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String title, String message, {SnackBarAction? action}) {
    if (!mounted) return; // Check if widget is still mounted
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          action: action,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Ignore errors if widget is disposed
      debugPrint('Error showing SnackBar: $e');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String title, String message) {
    if (!mounted) return; // Check if widget is still mounted
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Ignore errors if widget is disposed
      debugPrint('Error showing SnackBar: $e');
    }
  }

  Widget _buildOfferStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        break;
      case 'accepted':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.done_all;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback? onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isRetrying ? null : () {
                  setState(() {
                    _isRetrying = true;
                  });
                  onRetry();
                },
                icon: _isRetrying 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
                label: Text(_isRetrying ? 'Retrying...' : 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showOfferHistory(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Offer History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  key: ValueKey('offers_stream_${DateTime.now().millisecondsSinceEpoch}'),
                  stream: FirebaseFirestore.instance
                      .collection('offers')
                      .where('helperId', isEqualTo: currentUser.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(
                        'Unable to load your offer history. Please check your connection and try again.',
                        () {
                          // Use post-frame callback to avoid setState during build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No offer history found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your offer history will appear here once you start making offers',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final offerDoc = snapshot.data!.docs[index];
                        final offerData = offerDoc.data() as Map<String, dynamic>;
                        
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getRequestDetails(offerData['requestId'] ?? ''),
                          builder: (context, requestSnapshot) {
                            final requestData = requestSnapshot.data;
                            final timestamp = offerData['createdAt'] as Timestamp?;
                            final formattedDate = timestamp != null
                                ? DateFormat.yMd().add_jm().format(timestamp.toDate())
                                : 'Unknown date';

                            // Handle loading state for individual items
                            if (requestSnapshot.connectionState == ConnectionState.waiting) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Loading request details...',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            requestData?['title'] ?? 'Request no longer available',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: requestData == null ? Colors.grey : null,
                                            ),
                                          ),
                                        ),
                                        _buildOfferStatusChip(offerData['status'] ?? 'unknown'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (requestData != null) ...[
                                      Text(
                                        requestData['description'] ?? 'No description',
                                        style: TextStyle(color: Colors.grey[600]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs. ${requestData['price'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      // Show alternative price if proposed
                                      if (offerData['alternativePrice'] != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.price_change, size: 16, color: Colors.orange.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                'You proposed: Rs. ${(offerData['alternativePrice'] as num).toStringAsFixed(0)}',
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
                                      if (offerData['customMessage'] != null && 
                                          (offerData['customMessage'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.message, size: 16, color: Colors.blue.shade700),
                                                  const SizedBox(width: 4),
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
                                                offerData['customMessage'] as String,
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ] else ...[
                                      Text(
                                        'This request is no longer available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Offered on $formattedDate',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
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
                ),
              ),
            ],
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Show sign-in prompt if user is not authenticated
    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign in required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please sign in to view and make offers on requests',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to sign in screen
                  debugPrint('Navigate to sign in');
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshRequests,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('status', isEqualTo: 'open')
                .snapshots(),
            builder: (context, snapshot) {
            // Enhanced loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            // Enhanced error handling
            if (snapshot.hasError) {
              debugPrint('ViewOffersTab: Error loading requests: ${snapshot.error}');
              
              String errorMessage = 'Unable to load requests. Please check your connection and try again.';
              if (snapshot.error.toString().contains('permission-denied')) {
                errorMessage = 'You don\'t have permission to view requests.';
              } else if (snapshot.error.toString().contains('unavailable')) {
                errorMessage = 'Service is temporarily unavailable. Please try again later.';
              }
              
              return _buildErrorState(errorMessage, () {
                setState(() {
                  _isRetrying = false;
                });
              });
            }

            final docs = snapshot.data?.docs ?? [];

            // Enhanced empty state
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No requests available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'There are currently no open requests to help with. Check back later for new opportunities to help others!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Use post-frame callback to avoid setState during build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() {}); // Refresh
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort documents safely
            docs.sort((a, b) {
              try {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;
                final aTime = aData?['createdAt'] as Timestamp?;
                final bTime = bData?['createdAt'] as Timestamp?;
                
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              } catch (e) {
                debugPrint('ViewOffersTab: Error sorting documents: $e');
                return 0;
              }
            });

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};
                
                // Safely extract data with fallbacks
                final title = data['title']?.toString() ?? 'Untitled Request';
                final description = data['description']?.toString() ?? 'No description provided';
                final price = data['price']?.toString() ?? 'Not specified';
                final location = data['location']?.toString() ?? 'Location not specified';
                final requesterId = data['userId']?.toString() ?? '';
                final requesterUsername = data['username']?.toString() ?? 'Anonymous User';
                final timestamp = data['createdAt'] as Timestamp?;
                
                // TODO: Calculate actual distance using user's location
                final dummyDistance = '${((index + 1) * 0.5).toStringAsFixed(1)}';
                
                final formattedDate = timestamp != null
                    ? DateFormat.yMd().add_jm().format(timestamp.toDate())
                    : 'Date unknown';

                // Skip invalid requests
                if (requesterId.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Check if user already has an offer for this request
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('offers')
                      .where('helperId', isEqualTo: currentUser.uid)
                      .where('requestId', isEqualTo: doc.id)
                      .snapshots(),
                  builder: (context, offerSnapshot) {
                    final hasExistingOffer = offerSnapshot.hasData && 
                        offerSnapshot.data!.docs.isNotEmpty;
                    
                    final existingOfferStatus = hasExistingOffer 
                        ? (offerSnapshot.data!.docs.first.data() as Map<String, dynamic>)['status']
                        : null;

                    final isLoading = _loadingStates[doc.id] == true;

                    return GestureDetector(
                      onTap: () => _showRequestDetails(context, doc),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                Expanded(
                                  child: Text(
                                    title, 
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                    ),
                                  ),
                                ),
                                if (requesterUsername.isNotEmpty)
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'By: $requesterUsername',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (requesterId.isNotEmpty)
                                  UserStatusWidget(
                                    userId: requesterId,
                                    textStyle: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                    showDot: true,
                                  ),
                              ],
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: hasExistingOffer
                                                ? _buildOfferStatusChip(existingOfferStatus ?? 'unknown')
                                                : ElevatedButton(
                                                    onPressed: isLoading ? null : () => _makeOffer(
                                                      context,
                                                      doc.id,
                                                      requesterId,
                                                    ),
                                                    child: isLoading
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          )
                                                        : const Text('Interested'),
                                                  ),
                                          ),
                                        ],
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
                    )); // Close GestureDetector
                  },
                ); // Close StreamBuilder
              },
            ); // Close ListView.builder
          },
        ), // Close main StreamBuilder
        ), // Close RefreshIndicator
        // Enhanced bottom panel showing active offers    
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .where('helperId', isEqualTo: currentUser.uid)
                .where('status', whereIn: ['pending', 'accepted'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Unable to load active offers',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
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

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'No active offers',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showOfferHistory(context),
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('History'),
                      ),
                    ],
                  ),
                );
              }

              final activeOffers = snapshot.data!.docs;

              return Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${activeOffers.length} Active Offer${activeOffers.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showOfferHistory(context),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('History'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activeOffers.length,
                        itemBuilder: (context, index) {
                          final offerDoc = activeOffers[index];
                          final offerData = offerDoc.data() as Map<String, dynamic>;
                          
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FutureBuilder<Map<String, dynamic>?>(
                                  future: _getRequestDetails(offerData['requestId'] ?? ''),
                                  builder: (context, requestSnapshot) {
                                    final requestData = requestSnapshot.data;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                requestData?['title'] ?? 
                                                  (requestSnapshot.connectionState == ConnectionState.waiting 
                                                    ? 'Loading...' 
                                                    : 'Request unavailable'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _buildOfferStatusChip(offerData['status'] ?? 'unknown'),
                                          ],
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                requestData != null 
                                                  ? 'Rs. ${requestData['price'] ?? 'N/A'}'
                                                  : 'Price unavailable',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _cancelOffer(context, offerDoc.id),
                                              icon: const Icon(Icons.close, size: 16),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                              iconSize: 16,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
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
      _showSuccessSnackBar(context, 'Success', 'Offer cancelled successfully');
    } catch (e) {
      debugPrint('ViewOffersTab: Error cancelling offer: $e');
      _showErrorSnackBar(context, 'Failed to cancel', 'Unable to cancel offer. Please try again.');
    }
  }
}

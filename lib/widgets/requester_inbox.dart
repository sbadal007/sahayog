import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_status_widget.dart';

class RequesterInbox extends StatefulWidget {
  final String? userId;

  const RequesterInbox({super.key, this.userId});

  @override
  State<RequesterInbox> createState() => _RequesterInboxState();
}

class _RequesterInboxState extends State<RequesterInbox> with SingleTickerProviderStateMixin {
  late String currentUserId;
  late Stream<QuerySnapshot> _requestsStream;
  late Stream<QuerySnapshot> _offersStream;
  bool _showDebugInfo = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.userId ?? 'test-user';
    debugPrint('RequesterInbox: Initializing for userId: $currentUserId');
    _tabController = TabController(length: 2, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    try {
      _requestsStream = FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots();
      
      // Remove orderBy to avoid composite index requirement
      _offersStream = FirebaseFirestore.instance
          .collection('offers')
          .where('requesterId', isEqualTo: currentUserId)
          .snapshots();
      
      debugPrint('RequesterInbox: Streams initialized successfully');
    } catch (e) {
      debugPrint('RequesterInbox: Error initializing streams: $e');
    }
  }

  Future<void> _handleOffer(String offerId, String action, String requestId) async {
    try {
      String newStatus;
      switch (action) {
        case 'accept':
          newStatus = 'accepted';
          // Update request status to closed when offer is accepted
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(requestId)
              .update({'status': 'closed'});
          break;
        case 'reject':
          newStatus = 'rejected';
          break;
        default:
          return;
      }

      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer ${action}ed successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error handling offer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action offer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Incoming Offers'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showDebugInfo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.yellow[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('User ID: $currentUserId'),
                  Text('Collections: requests, offers'),
                  Text('Query: userId/requesterId == $currentUserId'),
                  ElevatedButton(
                    onPressed: _refreshStreams,
                    child: const Text('Refresh Streams'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildOffersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        debugPrint('RequesterInbox: Requests StreamBuilder state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          debugPrint('RequesterInbox: Error in requests stream: ${snapshot.error}');
          return _buildErrorWidget('requests', _refreshStreams);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading requests...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('RequesterInbox: No requests data or empty collection');
          return _buildEmptyState('requests');
        }

        final docs = snapshot.data!.docs;
        debugPrint('RequesterInbox: Found ${docs.length} requests');

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final request = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(doc.id, request);
          },
        );
      },
    );
  }

  Widget _buildOffersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _offersStream,
      builder: (context, snapshot) {
        debugPrint('RequesterInbox: Offers StreamBuilder state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          debugPrint('RequesterInbox: Error in offers stream: ${snapshot.error}');
          return _buildErrorWidget('offers', _refreshStreams);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading offers...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('RequesterInbox: No offers data or empty collection');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No offers received yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        debugPrint('RequesterInbox: Found ${docs.length} offers');

        // Sort offers in code instead of query to avoid index requirement
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final offer = doc.data() as Map<String, dynamic>;
            return _buildOfferCard(doc.id, offer);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String docId, Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'open';
    final createdAt = (request['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final preferredDate = (request['preferredDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request['title'] ?? 'No Title',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusButton(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request['description'] ?? 'No Description',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['location'] ?? 'No Location',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Rs. ${request['price']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Preferred: ${preferredDate.toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${createdAt.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (_showDebugInfo) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debug - Doc ID: $docId'),
                    Text('Debug - User ID: ${request['userId']}'),
                    Text('Debug - Status: $status'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(String offerId, Map<String, dynamic> offer) {
    final status = offer['status'] as String? ?? 'pending';
    final helperName = offer['helperName'] as String? ?? 'Anonymous Helper';
    final helperId = offer['helperId'] as String? ?? '';
    final createdAt = (offer['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final requestId = offer['requestId'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(helperName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(helperName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Interested in helping', style: TextStyle(color: Colors.grey[600])),
                      if (helperId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        UserStatusWidget(
                          userId: helperId,
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          showDot: true,
                        ),
                      ],
                    ],
                  ),
                ),
                _buildOfferStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('requests').doc(requestId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final requestData = snapshot.data!.data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('For: ${requestData['title'] ?? 'Unknown Request'}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('Price: Rs. ${requestData['price']?.toString() ?? 'N/A'}'),
                      ],
                    ),
                  );
                }
                return const Text('Loading request details...');
              },
            ),
            // Show alternative price if proposed
            if (offer['alternativePrice'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.price_change, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Proposed Price: Rs. ${(offer['alternativePrice'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
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
                padding: const EdgeInsets.all(8.0),
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
            const SizedBox(height: 12),
            Text('Offered on: ${createdAt.toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleOffer(offerId, 'accept', requestId),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleOffer(offerId, 'reject', requestId),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            if (_showDebugInfo) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debug - Offer ID: $offerId'),
                    Text('Debug - Helper ID: ${offer['helperId']}'),
                    Text('Debug - Request ID: $requestId'),
                    Text('Debug - Status: $status'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String type, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading $type'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No $type yet', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          if (_showDebugInfo) ...[
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _testCreateRequest, child: const Text('Create Test Request')),
          ],
        ],
      ),
    );
  }

  void _refreshStreams() {
    debugPrint('RequesterInbox: Refreshing streams...');
    setState(() {
      _initializeStreams();
    });
  }

  Future<void> _testCreateRequest() async {
    try {
      debugPrint('RequesterInbox: Creating test request...');
      await FirebaseFirestore.instance.collection('requests').add({
        'userId': currentUserId,
        'title': 'Test Request ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'This is a test request created for debugging',
        'price': 100.0,
        'location': 'Test Location',
        'preferredDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'latitude': 0.0,
        'longitude': 0.0,
        'status': 'open',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test request created!')),
        );
      }
    } catch (e) {
      debugPrint('RequesterInbox: Error creating test request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test request: $e')),
        );
      }
    }
  }

  Widget _buildStatusButton(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'closed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Completed', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case 'open':
      case 'pending':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pending, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Open', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewOffersTab extends StatelessWidget {
  const ViewOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No requests found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'No Title';
            final description = data['description'] ?? 'No Description';
            final price = data['price']?.toString() ?? 'N/A';
            final timestamp = data['createdAt'] as Timestamp?;
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
                    Text(title, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      )
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. $price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green
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
                    const SizedBox(height: 4),
                    Text(
                      formattedDate, 
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Colors.grey
                      )
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

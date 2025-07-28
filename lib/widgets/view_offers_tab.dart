import 'package:flutter/material.dart';

class ViewOffersTab extends StatelessWidget {
  const ViewOffersTab({super.key});

  final List<Map<String, String>> _offers = const [
    {
      'title': 'Need help moving furniture',
      'description': 'Need assistance moving heavy furniture from ground floor to 3rd floor',
      'price': 'Rs. 1000',
      'distance': '1.2km away'
    },
    {
      'title': 'Hospital Visit Companion',
      'description': 'Looking for someone to accompany elderly father for hospital checkup',
      'price': 'Rs. 800',
      'distance': '0.5km away'
    },
    {
      'title': 'Grocery Shopping Assistant',
      'description': 'Need help with weekly grocery shopping for elderly couple',
      'price': 'Rs. 500',
      'distance': '2.1km away'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _offers.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['title']!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(offer['description']!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${offer['price']} • ${offer['distance']}'),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening chat...')),
                        );
                      },
                      child: const Text('Chat Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

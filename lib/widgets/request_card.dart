// filepath: c:\Users\susma\Documents\sahayog\lib\widgets\request_card.dart
import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onActionPressed;

  const RequestCard({
    super.key,
    required this.title,
    required this.description,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: onActionPressed,
              child: const Text('Take Action'),
            ),
          ],
        ),
      ),
    );
  }
}
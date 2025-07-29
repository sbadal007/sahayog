import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_status_service.dart';

class UserStatusWidget extends StatelessWidget {
  final String userId;
  final TextStyle? textStyle;
  final bool showDot;

  const UserStatusWidget({
    super.key,
    required this.userId,
    this.textStyle,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            'Offline',
            style: textStyle ?? TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isOnline = userData['isOnline'] ?? false;
        final lastSeenTimestamp = userData['lastSeen'] as Timestamp?;

        String statusText;
        Color statusColor;

        if (isOnline) {
          statusText = 'Active now';
          statusColor = Colors.green;
        } else if (lastSeenTimestamp != null) {
          final lastSeen = lastSeenTimestamp.toDate();
          statusText = 'Last seen ${UserStatusService.formatLastSeen(lastSeen)}';
          statusColor = Colors.grey;
        } else {
          statusText = 'Offline';
          statusColor = Colors.grey;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              statusText,
              style: textStyle ?? TextStyle(
                color: statusColor,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

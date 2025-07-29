import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? additionalData,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': additionalData,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

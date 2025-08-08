// filepath: lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;
  final List<String>? attachments; // Future: image/file URLs
  final String type; // 'text', 'image', 'system'

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.readBy,
    this.attachments,
    this.type = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'attachments': attachments,
      'type': type,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      type: map['type'] ?? 'text',
    );
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? createdAt,
    List<String>? readBy,
    List<String>? attachments,
    String? type,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      attachments: attachments ?? this.attachments,
      type: type ?? this.type,
    );
  }

  // Helper methods
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  bool isSentBy(String userId) {
    return senderId == userId;
  }

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (messageDate == today) {
      // Today: show time only
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(createdAt).inDays < 7) {
      // This week: show day and time
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[createdAt.weekday - 1]} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      // Older: show date
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Create system messages for events
  static Message createSystemMessage({
    required String conversationId,
    required String text,
    String senderId = 'system',
    String senderName = 'System',
  }) {
    return Message(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: DateTime.now(),
      readBy: [],
      type: 'system',
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String offerId;
  final String? requestId; // Add requestId to link conversation to specific request
  final List<String> participants; // [requesterId, helperId]
  final DateTime lastMessageAt;
  final String lastMessageText;
  final Map<String, int> unreadCount; // userId -> count
  final bool isArchived;
  final DateTime? archivedAt;

  Conversation({
    required this.id,
    required this.offerId,
    this.requestId,
    required this.participants,
    required this.lastMessageAt,
    required this.lastMessageText,
    required this.unreadCount,
    this.isArchived = false,
    this.archivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'requestId': requestId,
      'participants': participants,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageText': lastMessageText,
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    return Conversation(
      id: id,
      offerId: map['offerId']?.toString() ?? '',
      requestId: map['requestId']?.toString(),
      participants: List<String>.from(map['participants'] ?? []),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageText: map['lastMessageText']?.toString() ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isArchived: map['isArchived'] ?? false,
      archivedAt: (map['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Conversation copyWith({
    String? id,
    String? offerId,
    List<String>? participants,
    DateTime? lastMessageAt,
    String? lastMessageText,
    Map<String, int>? unreadCount,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      participants: participants ?? this.participants,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  // Helper methods
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }
}

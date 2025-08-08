import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String requestId;
  final String helperId;
  final String helperName;
  final String requesterId;
  final String status;
  final DateTime createdAt;
  final String? customMessage;
  final double? alternativePrice;
  final String? conversationId; // Link to chat conversation

  Offer({
    required this.id,
    required this.requestId,
    required this.helperId,
    required this.helperName,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.customMessage,
    this.alternativePrice,
    this.conversationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'helperId': helperId,
      'helperName': helperName,
      'requesterId': requesterId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'customMessage': customMessage,
      'alternativePrice': alternativePrice,
      'conversationId': conversationId,
    };
  }

  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      id: id,
      requestId: map['requestId'] ?? '',
      helperId: map['helperId'] ?? '',
      helperName: map['helperName'] ?? '',
      requesterId: map['requesterId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customMessage: map['customMessage'],
      alternativePrice: map['alternativePrice']?.toDouble(),
      conversationId: map['conversationId'],
    );
  }

  // Create a copy with updated fields
  Offer copyWith({
    String? id,
    String? requestId,
    String? helperId,
    String? helperName,
    String? requesterId,
    String? status,
    DateTime? createdAt,
    String? customMessage,
    double? alternativePrice,
    String? conversationId,
  }) {
    return Offer(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      helperId: helperId ?? this.helperId,
      helperName: helperName ?? this.helperName,
      requesterId: requesterId ?? this.requesterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customMessage: customMessage ?? this.customMessage,
      alternativePrice: alternativePrice ?? this.alternativePrice,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  // Helper method to check if offer has custom terms
  bool get hasCustomTerms => customMessage != null || alternativePrice != null;

  // Helper method to get formatted alternative price
  String get formattedAlternativePrice {
    if (alternativePrice == null) return '';
    return 'Rs. ${alternativePrice!.toStringAsFixed(0)}';
  }
}

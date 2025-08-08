import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String requestId;
  final String offerId;
  final String reviewerId; // Person giving the rating
  final String revieweeId; // Person being rated
  final String reviewerName;
  final String revieweeName;
  final double rating; // 1-5 stars
  final String? review; // Optional text review
  final String reviewType; // 'helper_to_requester', 'requester_to_helper'
  final DateTime createdAt;
  final bool isVisible; // For moderation purposes

  Rating({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerName,
    required this.revieweeName,
    required this.rating,
    this.review,
    required this.reviewType,
    required this.createdAt,
    this.isVisible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'offerId': offerId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'reviewerName': reviewerName,
      'revieweeName': revieweeName,
      'rating': rating,
      'review': review,
      'reviewType': reviewType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVisible': isVisible,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map, String id) {
    return Rating(
      id: id,
      requestId: map['requestId'] ?? '',
      offerId: map['offerId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      revieweeName: map['revieweeName'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      review: map['review'],
      reviewType: map['reviewType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVisible: map['isVisible'] ?? true,
    );
  }

  // Create a copy with updated fields
  Rating copyWith({
    String? id,
    String? requestId,
    String? offerId,
    String? reviewerId,
    String? revieweeId,
    String? reviewerName,
    String? revieweeName,
    double? rating,
    String? review,
    String? reviewType,
    DateTime? createdAt,
    bool? isVisible,
  }) {
    return Rating(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      offerId: offerId ?? this.offerId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      reviewerName: reviewerName ?? this.reviewerName,
      revieweeName: revieweeName ?? this.revieweeName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      reviewType: reviewType ?? this.reviewType,
      createdAt: createdAt ?? this.createdAt,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  // Helper method to get formatted rating
  String get formattedRating => rating.toStringAsFixed(1);

  // Helper method to get star display
  String get starDisplay {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    
    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    stars += '☆' * emptyStars;
    
    return stars;
  }

  // Helper method to check if review has text
  bool get hasReviewText => review != null && review!.trim().isNotEmpty;
}

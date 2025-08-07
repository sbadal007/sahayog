class UserRatingSummary {
  final String userId;
  final double averageRating;
  final int totalRatings;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final DateTime lastUpdated;

  UserRatingSummary({
    required this.userId,
    required this.averageRating,
    required this.totalRatings,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'fiveStarCount': fiveStarCount,
      'fourStarCount': fourStarCount,
      'threeStarCount': threeStarCount,
      'twoStarCount': twoStarCount,
      'oneStarCount': oneStarCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserRatingSummary.fromMap(Map<String, dynamic> map) {
    return UserRatingSummary(
      userId: map['userId'] ?? '',
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      fiveStarCount: map['fiveStarCount'] ?? 0,
      fourStarCount: map['fourStarCount'] ?? 0,
      threeStarCount: map['threeStarCount'] ?? 0,
      twoStarCount: map['twoStarCount'] ?? 0,
      oneStarCount: map['oneStarCount'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper method to get formatted average rating
  String get formattedAverageRating => averageRating.toStringAsFixed(1);

  // Helper method to get star display for average rating
  String get starDisplay {
    final fullStars = averageRating.floor();
    final hasHalfStar = (averageRating - fullStars) >= 0.5;
    
    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    stars += '☆' * emptyStars;
    
    return stars;
  }

  // Helper method to check if user has any ratings
  bool get hasRatings => totalRatings > 0;

  // Helper method to get rating distribution percentages
  Map<int, double> get ratingDistribution {
    if (totalRatings == 0) return {};
    
    return {
      5: (fiveStarCount / totalRatings) * 100,
      4: (fourStarCount / totalRatings) * 100,
      3: (threeStarCount / totalRatings) * 100,
      2: (twoStarCount / totalRatings) * 100,
      1: (oneStarCount / totalRatings) * 100,
    };
  }

  // Create an empty rating summary for new users
  factory UserRatingSummary.empty(String userId) {
    return UserRatingSummary(
      userId: userId,
      averageRating: 0.0,
      totalRatings: 0,
      fiveStarCount: 0,
      fourStarCount: 0,
      threeStarCount: 0,
      twoStarCount: 0,
      oneStarCount: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

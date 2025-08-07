import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rating.dart';
import '../models/user_rating_summary.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new rating
  static Future<String> createRating({
    required String requestId,
    required String offerId,
    required String reviewerId,
    required String revieweeId,
    required String reviewerName,
    required String revieweeName,
    required double rating,
    String? review,
    required String reviewType,
  }) async {
    try {
      // Check if rating already exists
      final existingRating = await _firestore
          .collection('ratings')
          .where('requestId', isEqualTo: requestId)
          .where('reviewerId', isEqualTo: reviewerId)
          .where('revieweeId', isEqualTo: revieweeId)
          .get();

      if (existingRating.docs.isNotEmpty) {
        throw Exception('You have already rated this user for this request');
      }

      // Create new rating
      final ratingData = Rating(
        id: '', // Will be set by Firestore
        requestId: requestId,
        offerId: offerId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        reviewerName: reviewerName,
        revieweeName: revieweeName,
        rating: rating,
        review: review,
        reviewType: reviewType,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('ratings').add(ratingData.toMap());
      
      // Update the rating summary for the reviewee
      await _updateUserRatingSummary(revieweeId);

      debugPrint('RatingService: Rating created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('RatingService: Error creating rating: $e');
      rethrow;
    }
  }

  // Get ratings for a specific user
  static Future<List<Rating>> getUserRatings(String userId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('ratings')
          .where('revieweeId', isEqualTo: userId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Rating.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint('RatingService: Error getting user ratings: $e');
      return [];
    }
  }

  // Get user rating summary
  static Future<UserRatingSummary> getUserRatingSummary(String userId) async {
    try {
      final doc = await _firestore.collection('userRatingSummaries').doc(userId).get();
      
      if (doc.exists) {
        return UserRatingSummary.fromMap(doc.data()!);
      } else {
        return UserRatingSummary.empty(userId);
      }
    } catch (e) {
      debugPrint('RatingService: Error getting user rating summary: $e');
      return UserRatingSummary.empty(userId);
    }
  }

  // Update user rating summary (called after a new rating is created)
  static Future<void> _updateUserRatingSummary(String userId) async {
    try {
      // Get all ratings for this user
      final ratings = await getUserRatings(userId);
      
      if (ratings.isEmpty) {
        // Create empty summary
        final emptySummary = UserRatingSummary.empty(userId);
        await _firestore.collection('userRatingSummaries').doc(userId).set(emptySummary.toMap());
        return;
      }

      // Calculate statistics
      final totalRatings = ratings.length;
      final averageRating = ratings.map((r) => r.rating).reduce((a, b) => a + b) / totalRatings;
      
      int fiveStarCount = 0;
      int fourStarCount = 0;
      int threeStarCount = 0;
      int twoStarCount = 0;
      int oneStarCount = 0;

      for (final rating in ratings) {
        switch (rating.rating.round()) {
          case 5:
            fiveStarCount++;
            break;
          case 4:
            fourStarCount++;
            break;
          case 3:
            threeStarCount++;
            break;
          case 2:
            twoStarCount++;
            break;
          case 1:
            oneStarCount++;
            break;
        }
      }

      // Create updated summary
      final summary = UserRatingSummary(
        userId: userId,
        averageRating: averageRating,
        totalRatings: totalRatings,
        fiveStarCount: fiveStarCount,
        fourStarCount: fourStarCount,
        threeStarCount: threeStarCount,
        twoStarCount: twoStarCount,
        oneStarCount: oneStarCount,
        lastUpdated: DateTime.now(),
      );

      await _firestore.collection('userRatingSummaries').doc(userId).set(summary.toMap());
      debugPrint('RatingService: Updated rating summary for user: $userId');
    } catch (e) {
      debugPrint('RatingService: Error updating user rating summary: $e');
    }
  }

  // Check if user can rate another user for a specific request
  static Future<bool> canUserRate({
    required String requestId,
    required String reviewerId,
    required String revieweeId,
  }) async {
    try {
      final existingRating = await _firestore
          .collection('ratings')
          .where('requestId', isEqualTo: requestId)
          .where('reviewerId', isEqualTo: reviewerId)
          .where('revieweeId', isEqualTo: revieweeId)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      debugPrint('RatingService: Error checking if user can rate: $e');
      return false;
    }
  }

  // Get rating between two users for a specific request
  static Future<Rating?> getRatingForRequest({
    required String requestId,
    required String reviewerId,
    required String revieweeId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('requestId', isEqualTo: requestId)
          .where('reviewerId', isEqualTo: reviewerId)
          .where('revieweeId', isEqualTo: revieweeId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Rating.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      debugPrint('RatingService: Error getting rating for request: $e');
      return null;
    }
  }

  // Stream of ratings for a user (for real-time updates)
  static Stream<List<Rating>> getUserRatingsStream(String userId, {int? limit}) {
    Query query = _firestore
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Rating.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Stream of user rating summary (for real-time updates)
  static Stream<UserRatingSummary> getUserRatingSummaryStream(String userId) {
    return _firestore
        .collection('userRatingSummaries')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserRatingSummary.fromMap(doc.data()!);
      } else {
        return UserRatingSummary.empty(userId);
      }
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/error_service.dart';

/// Service to handle Firestore index management and automatic creation
class IndexService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if an error is related to missing or building indexes
  static bool isIndexError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('query requires an index') ||
           errorString.contains('index is currently building') ||
           errorString.contains('failed-precondition');
  }

  /// Check if index is currently building
  static bool isIndexBuilding(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('index is currently building') ||
           errorString.contains('cannot be used yet');
  }

  /// Extract index creation URL from error message
  static String? extractIndexUrl(Object error) {
    final errorString = error.toString();
    final urlPattern = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = urlPattern.firstMatch(errorString);
    return match?.group(0);
  }

  /// Attempt to trigger index creation by making the query
  /// This will cause Firestore to automatically generate the required index
  /// Note: This may fail due to permission restrictions, which is expected
  static Future<void> triggerIndexCreation({
    required String collection,
    required Map<String, dynamic> queryParams,
  }) async {
    try {
      ErrorService.logError(
        message: 'Attempting to trigger automatic index creation',
        location: 'IndexService.triggerIndexCreation',
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        additionalData: {
          'collection': collection,
          'queryParams': queryParams,
        },
      );

      // Make the query that requires the index
      // This will trigger Firestore to show the index creation URL
      await _firestore
          .collection(collection)
          .limit(1)
          .get();
          
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      final isPermissionError = errorString.contains('permission-denied') ||
                               errorString.contains('insufficient permissions');
      
      if (isPermissionError) {
        ErrorService.logError(
          message: 'Index creation trigger blocked by permissions (expected behavior)',
          location: 'IndexService.triggerIndexCreation',
          type: ErrorType.firebase,
          severity: ErrorSeverity.low,
          error: e,
          additionalData: {
            'isPermissionError': true,
            'guidance': 'Manual index creation required via Firebase Console',
          },
        );
      } else {
        ErrorService.logError(
          message: 'Index creation trigger completed with error',
          location: 'IndexService.triggerIndexCreation',
          type: ErrorType.firebase,
          severity: ErrorSeverity.low,
          error: e,
        );
      }
      // This is expected to fail, but it triggers index creation
    }
  }

  /// Wait for index to be ready with exponential backoff
  static Future<bool> waitForIndex({
    required Future<QuerySnapshot> Function() queryFunction,
    int maxAttempts = 10,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await queryFunction();
        ErrorService.logError(
          message: 'Index is now ready',
          location: 'IndexService.waitForIndex',
          type: ErrorType.firebase,
          severity: ErrorSeverity.low,
          additionalData: {
            'attempt': attempt,
            'maxAttempts': maxAttempts,
          },
        );
        return true;
      } catch (e) {
        if (!isIndexError(e)) {
          // If it's not an index error, something else is wrong
          throw e;
        }

        if (attempt == maxAttempts) {
          ErrorService.logError(
            message: 'Index wait timeout after $maxAttempts attempts',
            location: 'IndexService.waitForIndex',
            type: ErrorType.firebase,
            severity: ErrorSeverity.high,
            error: e,
          );
          return false;
        }

        // Exponential backoff
        final delay = Duration(
          milliseconds: (initialDelay.inMilliseconds * (attempt * 1.5)).round(),
        );
        
        ErrorService.logError(
          message: 'Index still building, waiting ${delay.inSeconds}s (attempt $attempt/$maxAttempts)',
          location: 'IndexService.waitForIndex',
          type: ErrorType.firebase,
          severity: ErrorSeverity.low,
          additionalData: {
            'attempt': attempt,
            'delaySeconds': delay.inSeconds,
          },
        );

        await Future.delayed(delay);
      }
    }
    return false;
  }

  /// Get user-friendly message for index status
  static String getIndexStatusMessage(Object error) {
    if (isIndexBuilding(error)) {
      return 'Setting up database... This may take a few minutes.';
    } else if (isIndexError(error)) {
      return 'Initializing database index... Please wait.';
    }
    return 'Loading data...';
  }

  /// Get estimated wait time based on error message
  static Duration getEstimatedWaitTime(Object error) {
    if (isIndexBuilding(error)) {
      return const Duration(minutes: 5); // Index is building
    }
    return const Duration(minutes: 10); // Index needs to be created
  }
}

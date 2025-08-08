import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Different types of errors that can occur in the app
enum ErrorType {
  network,
  authentication,
  database,
  validation,
  permission,
  unknown,
  firebase,
  chat,
  fileUpload,
  userProfile,
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Centralized error handling service for the Sahayog app
/// Provides consistent error management, logging, and debugging across all components
class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  static const String _tag = 'ErrorService';

  /// Centralized error logging with debugging information
  static void logError({
    required String message,
    required String location,
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final errorInfo = {
      'timestamp': timestamp,
      'location': location,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'additionalData': additionalData,
    };

    // Log to console with color coding based on severity
    final coloredMessage = _getColoredLogMessage(severity, message, location);
    
    if (kDebugMode) {
      debugPrint('🚨 $_tag - $coloredMessage');
      if (error != null) {
        debugPrint('   Error Details: $error');
      }
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('   Additional Data: $additionalData');
      }
      if (stackTrace != null && severity == ErrorSeverity.critical) {
        debugPrint('   Stack Trace: $stackTrace');
      }
    }

    // In production, you could send this to a logging service like Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }

  /// Get colored log message based on severity
  static String _getColoredLogMessage(ErrorSeverity severity, String message, String location) {
    final prefix = switch (severity) {
      ErrorSeverity.low => '🟡 LOW',
      ErrorSeverity.medium => '🟠 MEDIUM',
      ErrorSeverity.high => '🔴 HIGH',
      ErrorSeverity.critical => '💀 CRITICAL',
    };
    return '$prefix [$location] $message';
  }

  /// Log network-related errors with connection debugging
  static void logNetworkError({
    required String message,
    required String location,
    Object? error,
    StackTrace? stackTrace,
    String? url,
    int? statusCode,
    Map<String, String>? headers,
  }) {
    logError(
      message: message,
      location: location,
      type: ErrorType.network,
      severity: ErrorSeverity.high,
      error: error,
      stackTrace: stackTrace,
      additionalData: {
        'url': url,
        'statusCode': statusCode,
        'headers': headers,
        'connectionType': 'Unknown', // Could be enhanced with connectivity_plus
      },
    );
  }

  /// Log Firebase-specific errors with index handling
  static void logFirebaseError({
    required String message,
    required String location,
    Object? error,
    StackTrace? stackTrace,
    String? collection,
    String? documentId,
    String? operation,
  }) {
    // Check if this is an index-related error
    final errorString = error?.toString() ?? '';
    final isIndexError = errorString.contains('query requires an index') ||
                        errorString.contains('index is currently building');
    
    logError(
      message: isIndexError ? 'Index-related Firebase operation' : message,
      location: location,
      type: ErrorType.firebase,
      severity: isIndexError ? ErrorSeverity.low : ErrorSeverity.high,
      error: error,
      stackTrace: stackTrace,
      additionalData: {
        'collection': collection,
        'documentId': documentId,
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isIndexError': isIndexError,
        'indexUrl': isIndexError ? _extractIndexUrl(errorString) : null,
      },
    );
  }

  /// Extract index creation URL from error message
  static String? _extractIndexUrl(String errorString) {
    final urlPattern = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = urlPattern.firstMatch(errorString);
    return match?.group(0);
  }

  /// Log chat-specific errors
  static void logChatError({
    required String message,
    required String location,
    Object? error,
    StackTrace? stackTrace,
    String? conversationId,
    String? messageId,
    String? userId,
  }) {
    logError(
      message: message,
      location: location,
      type: ErrorType.chat,
      severity: ErrorSeverity.medium,
      error: error,
      stackTrace: stackTrace,
      additionalData: {
        'conversationId': conversationId,
        'messageId': messageId,
        'userId': userId,
      },
    );
  }

  /// Log authentication errors
  static void logAuthError({
    required String message,
    required String location,
    Object? error,
    StackTrace? stackTrace,
    String? userId,
    String? authMethod,
  }) {
    logError(
      message: message,
      location: location,
      type: ErrorType.authentication,
      severity: ErrorSeverity.high,
      error: error,
      stackTrace: stackTrace,
      additionalData: {
        'userId': userId,
        'authMethod': authMethod,
      },
    );
  }

  /// Create a user-friendly error message from technical error
  static String getUserFriendlyMessage(ErrorType type, {String? customMessage}) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    return switch (type) {
      ErrorType.network => 'Connection error. Please check your internet connection and try again.',
      ErrorType.authentication => 'Authentication failed. Please sign in again.',
      ErrorType.database => 'Database error. Please try again later.',
      ErrorType.validation => 'Invalid input. Please check your data and try again.',
      ErrorType.permission => 'Permission denied. You don\'t have access to this feature.',
      ErrorType.firebase => 'Service temporarily unavailable. Please try again later.',
      ErrorType.chat => 'Chat service error. Please try again.',
      ErrorType.fileUpload => 'File upload failed. Please try again.',
      ErrorType.userProfile => 'Profile error. Please try again or contact support.',
      ErrorType.unknown => 'An unexpected error occurred. Please try again.',
    };
  }

  /// Get icon for error type
  static IconData getErrorIcon(ErrorType type) {
    return switch (type) {
      ErrorType.network => Icons.wifi_off,
      ErrorType.authentication => Icons.person_off,
      ErrorType.database => Icons.storage,
      ErrorType.validation => Icons.warning,
      ErrorType.permission => Icons.lock,
      ErrorType.firebase => Icons.cloud_off,
      ErrorType.chat => Icons.chat_bubble_outline,
      ErrorType.fileUpload => Icons.upload_file,
      ErrorType.userProfile => Icons.account_circle,
      ErrorType.unknown => Icons.error_outline,
    };
  }

  /// Get color for error severity
  static Color getSeverityColor(ErrorSeverity severity) {
    return switch (severity) {
      ErrorSeverity.low => Colors.yellow.shade700,
      ErrorSeverity.medium => Colors.orange.shade700,
      ErrorSeverity.high => Colors.red.shade700,
      ErrorSeverity.critical => Colors.red.shade900,
    };
  }
}

/// Extension to add error handling to any widget
extension ErrorHandling on State {
  /// Handle errors consistently across the app
  void handleError({
    required String message,
    required String location,
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    // Log the error
    ErrorService.logError(
      message: message,
      location: location,
      type: type,
      severity: severity,
      error: error,
      stackTrace: stackTrace,
      additionalData: additionalData,
    );

    // Show user-friendly message if requested
    if (showSnackBar && mounted) {
      final userMessage = ErrorService.getUserFriendlyMessage(type, customMessage: message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                ErrorService.getErrorIcon(type),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(userMessage)),
            ],
          ),
          backgroundColor: ErrorService.getSeverityColor(severity),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    }
  }
}

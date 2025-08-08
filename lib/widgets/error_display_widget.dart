import 'package:flutter/material.dart';
import '../services/error_service.dart';

/// Centralized error display widget that can be used throughout the app
/// Provides consistent error UI with retry functionality and debugging info
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final String location;
  final ErrorType type;
  final ErrorSeverity severity;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool showDetails;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? debugInfo;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    required this.location,
    this.type = ErrorType.unknown,
    this.severity = ErrorSeverity.medium,
    this.onRetry,
    this.onCancel,
    this.showDetails = false,
    this.error,
    this.stackTrace,
    this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    final userMessage = ErrorService.getUserFriendlyMessage(type, customMessage: message);
    final icon = ErrorService.getErrorIcon(type);
    final color = ErrorService.getSeverityColor(severity);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 24),
            Text(
              userMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showDetails && error != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Error Details',
                  style: TextStyle(fontSize: 14),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location: $location',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${type.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Severity: ${severity.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if (debugInfo != null && debugInfo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Debug Info: ${debugInfo.toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onCancel != null) ...[
                  OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                ],
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen error page that can be navigated to
class ErrorScreen extends StatelessWidget {
  final String message;
  final String location;
  final ErrorType type;
  final ErrorSeverity severity;
  final VoidCallback? onRetry;
  final bool showDetails;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? debugInfo;

  const ErrorScreen({
    super.key,
    required this.message,
    required this.location,
    this.type = ErrorType.unknown,
    this.severity = ErrorSeverity.medium,
    this.onRetry,
    this.showDetails = false,
    this.error,
    this.stackTrace,
    this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: ErrorService.getSeverityColor(severity),
        foregroundColor: Colors.white,
      ),
      body: ErrorDisplayWidget(
        message: message,
        location: location,
        type: type,
        severity: severity,
        onRetry: onRetry,
        onCancel: () => Navigator.of(context).pop(),
        showDetails: showDetails,
        error: error,
        stackTrace: stackTrace,
        debugInfo: debugInfo,
      ),
    );
  }
}

/// Dialog version of error display
class ErrorDialog extends StatelessWidget {
  final String message;
  final String location;
  final ErrorType type;
  final ErrorSeverity severity;
  final VoidCallback? onRetry;
  final bool showDetails;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? debugInfo;

  const ErrorDialog({
    super.key,
    required this.message,
    required this.location,
    this.type = ErrorType.unknown,
    this.severity = ErrorSeverity.medium,
    this.onRetry,
    this.showDetails = false,
    this.error,
    this.stackTrace,
    this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    final userMessage = ErrorService.getUserFriendlyMessage(type, customMessage: message);
    final icon = ErrorService.getErrorIcon(type);
    final color = ErrorService.getSeverityColor(severity);

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          const Text('Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userMessage),
          if (showDetails && error != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Details'),
              children: [
                Text(
                  'Location: $location\nType: ${type.name}\nError: ${error.toString()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    required String location,
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry,
    bool showDetails = false,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? debugInfo,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        message: message,
        location: location,
        type: type,
        severity: severity,
        onRetry: onRetry,
        showDetails: showDetails,
        error: error,
        stackTrace: stackTrace,
        debugInfo: debugInfo,
      ),
    );
  }
}

/// Utility methods for handling errors consistently
class ErrorHandlerUtils {
  /// Show error as bottom sheet
  static void showErrorBottomSheet(
    BuildContext context, {
    required String message,
    required String location,
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry,
    bool showDetails = false,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? debugInfo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ErrorDisplayWidget(
            message: message,
            location: location,
            type: type,
            severity: severity,
            onRetry: onRetry,
            onCancel: () => Navigator.of(context).pop(),
            showDetails: showDetails,
            error: error,
            stackTrace: stackTrace,
            debugInfo: debugInfo,
          ),
        ),
      ),
    );
  }

  /// Navigate to error screen
  static void navigateToErrorScreen(
    BuildContext context, {
    required String message,
    required String location,
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry,
    bool showDetails = false,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? debugInfo,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ErrorScreen(
          message: message,
          location: location,
          type: type,
          severity: severity,
          onRetry: onRetry,
          showDetails: showDetails,
          error: error,
          stackTrace: stackTrace,
          debugInfo: debugInfo,
        ),
      ),
    );
  }
}

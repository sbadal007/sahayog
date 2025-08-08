import 'dart:async';
import 'package:flutter/material.dart';
import '../services/error_service.dart';
import '../services/index_service.dart';
import 'error_display_widget.dart';

/// A wrapper widget that catches errors from child widgets and displays them nicely
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String location;
  final Widget Function(Object error, StackTrace? stackTrace)? fallbackBuilder;
  final bool logErrors;
  final bool showErrorDetails;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.location,
    this.fallbackBuilder,
    this.logErrors = true,
    this.showErrorDetails = false,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(_error!, _stackTrace);
      }

      return ErrorDisplayWidget(
        message: 'Something went wrong in ${widget.location}',
        location: widget.location,
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
        error: _error,
        stackTrace: _stackTrace,
        showDetails: widget.showErrorDetails,
      );
    }

    return ErrorCatcher(
      onError: (error, stackTrace) {
        if (widget.logErrors) {
          ErrorService.logError(
            message: 'Error caught in ErrorBoundary',
            location: widget.location,
            error: error,
            stackTrace: stackTrace,
            type: ErrorType.unknown,
            severity: ErrorSeverity.medium,
          );
        }
        
        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      },
      child: widget.child,
    );
  }
}

/// Widget that catches Flutter framework errors
class ErrorCatcher extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  const ErrorCatcher({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    
    // Override the error handler for this widget subtree
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack);
    };
  }
}

/// A Future builder with built-in error handling
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final String location;
  final ErrorType errorType;

  const SafeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    required this.location,
    this.loadingBuilder,
    this.errorBuilder,
    this.errorType = ErrorType.unknown,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? 
                 const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          ErrorService.logError(
            message: 'Future failed in SafeFutureBuilder',
            location: location,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            type: errorType,
            severity: ErrorSeverity.medium,
          );

          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }

          return ErrorDisplayWidget(
            message: 'Failed to load data',
            location: location,
            type: errorType,
            severity: ErrorSeverity.medium,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            showDetails: true,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        return builder(context, snapshot.data!);
      },
    );
  }
}

/// A Stream builder with built-in error handling and index management
class SafeStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final String location;
  final ErrorType errorType;
  final VoidCallback? onRetry;

  const SafeStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    required this.location,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.errorType = ErrorType.unknown,
    this.onRetry,
  });

  @override
  State<SafeStreamBuilder<T>> createState() => _SafeStreamBuilderState<T>();
}

class _SafeStreamBuilderState<T> extends State<SafeStreamBuilder<T>> {
  bool _isIndexBuilding = false;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 10;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _handleIndexError(Object error) {
    if (IndexService.isIndexError(error)) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isIndexBuilding = true;
          });
        }
      });

      // Log the index building status
      ErrorService.logError(
        message: 'Index building detected, starting automatic retry',
        location: widget.location,
        error: error,
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        additionalData: {
          'isIndexBuilding': IndexService.isIndexBuilding(error),
          'indexUrl': IndexService.extractIndexUrl(error),
          'retryAttempts': _retryAttempts,
        },
      );

      // Start automatic retry with exponential backoff
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    
    if (_retryAttempts >= _maxRetryAttempts) {
      setState(() {
        _isIndexBuilding = false;
      });
      return;
    }

    _retryAttempts++;
    
    // Exponential backoff: 2s, 4s, 8s, 16s, etc., max 60s
    final delay = Duration(
      seconds: (2 * _retryAttempts).clamp(2, 60),
    );

    ErrorService.logError(
      message: 'Scheduling retry in ${delay.inSeconds}s (attempt $_retryAttempts/$_maxRetryAttempts)',
      location: widget.location,
      type: ErrorType.firebase,
      severity: ErrorSeverity.low,
      additionalData: {
        'retryAttempts': _retryAttempts,
        'delaySeconds': delay.inSeconds,
      },
    );

    _retryTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          // This will trigger the StreamBuilder to rebuild
        });
      }
    });
  }

  Widget _buildIndexBuildingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Setting up database...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few minutes. The app will automatically refresh when ready.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Attempt $_retryAttempts of $_maxRetryAttempts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isIndexBuilding) {
      return _buildIndexBuildingWidget();
    }

    return StreamBuilder<T>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? 
                 const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Check if this is an index-related error
          if (IndexService.isIndexError(snapshot.error!)) {
            // Handle index error without setState during build
            if (!_isIndexBuilding) {
              _handleIndexError(snapshot.error!);
            }
            return _buildIndexBuildingWidget();
          }

          // Regular error handling for non-index errors
          ErrorService.logError(
            message: 'Stream failed in SafeStreamBuilder',
            location: widget.location,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            type: widget.errorType,
            severity: ErrorSeverity.medium,
          );

          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }

          return ErrorDisplayWidget(
            message: 'Failed to load data stream',
            location: widget.location,
            type: widget.errorType,
            severity: ErrorSeverity.medium,
            onRetry: widget.onRetry,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            showDetails: true,
          );
        }

        // Reset retry state on successful data
        if (snapshot.hasData && _isIndexBuilding) {
          _retryTimer?.cancel();
          _retryAttempts = 0;
          _isIndexBuilding = false;
          
          ErrorService.logError(
            message: 'Index is now ready and data loaded successfully',
            location: widget.location,
            type: ErrorType.firebase,
            severity: ErrorSeverity.low,
          );
        }

        if (!snapshot.hasData) {
          return widget.emptyBuilder?.call(context) ?? 
                 const Center(child: Text('No data available'));
        }

        return widget.builder(context, snapshot.data!);
      },
    );
  }
}

/// Network-aware error handling widget
class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final String location;
  final VoidCallback? onRetry;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    required this.location,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // In a real app, you would use connectivity_plus package to check network status
    // For now, we'll just wrap the child with error handling
    return ErrorBoundary(
      location: location,
      child: child,
      fallbackBuilder: (error, stackTrace) {
        // Check if this looks like a network error
        final errorString = error.toString().toLowerCase();
        final isNetworkError = errorString.contains('network') ||
                              errorString.contains('connection') ||
                              errorString.contains('timeout') ||
                              errorString.contains('socket');

        if (isNetworkError) {
          ErrorService.logNetworkError(
            message: 'Network error detected',
            location: location,
            error: error,
            stackTrace: stackTrace,
          );

          return ErrorDisplayWidget(
            message: 'Network connection problem',
            location: location,
            type: ErrorType.network,
            severity: ErrorSeverity.high,
            onRetry: onRetry,
            error: error,
            showDetails: true,
          );
        }

        // Default error handling
        return ErrorDisplayWidget(
          message: 'Something went wrong',
          location: location,
          type: ErrorType.unknown,
          severity: ErrorSeverity.medium,
          onRetry: onRetry,
          error: error,
          showDetails: true,
        );
      },
    );
  }
}

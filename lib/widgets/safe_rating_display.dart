import 'package:flutter/material.dart';
import '../services/error_service.dart';
import '../services/index_service.dart';
import '../services/rating_service.dart';
import '../models/user_rating_summary.dart';

/// Widget to display when rating/review data cannot be loaded due to index issues
class RatingIndexPlaceholder extends StatelessWidget {
  final String userId;
  final VoidCallback? onRetry;

  const RatingIndexPlaceholder({
    super.key,
    required this.userId,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_border_outlined,
            size: 48,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Reviews Loading...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up review database. This may take a few minutes on first use.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Please wait...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Check Again'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced rating display widget with error handling
class SafeRatingDisplay extends StatefulWidget {
  final String userId;
  final Widget Function(BuildContext context, double averageRating, int totalRatings) builder;
  final Widget? errorWidget;

  const SafeRatingDisplay({
    super.key,
    required this.userId,
    required this.builder,
    this.errorWidget,
  });

  @override
  State<SafeRatingDisplay> createState() => _SafeRatingDisplayState();
}

class _SafeRatingDisplayState extends State<SafeRatingDisplay> {
  bool _hasIndexError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasIndexError) {
      return widget.errorWidget ?? 
             RatingIndexPlaceholder(
               userId: widget.userId,
               onRetry: () {
                 setState(() {
                   _hasIndexError = false;
                 });
               },
             );
    }

    return StreamBuilder<UserRatingSummary>(
      stream: RatingService.getUserRatingSummaryStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          if (IndexService.isIndexError(snapshot.error!)) {
            ErrorService.logFirebaseError(
              message: 'Rating display index error',
              location: 'SafeRatingDisplay',
              error: snapshot.error,
              collection: 'ratings',
              operation: 'get_rating_summary',
            );
            
            setState(() {
              _hasIndexError = true;
            });
            return Container(); // Will rebuild with placeholder
          }

          // Other errors
          return widget.errorWidget ??
                 const Icon(Icons.error_outline, color: Colors.red, size: 16);
        }

        if (!snapshot.hasData) {
          // No rating data available
          return widget.builder(context, 0.0, 0);
        }

        final summary = snapshot.data!;
        return widget.builder(context, summary.averageRating, summary.totalRatings);
      },
    );
  }
}

/// Simple rating stars widget with fallback
class RatingStarsWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showCount;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRatings == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border,
            size: size,
            color: Colors.grey[400],
          ),
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: size * 0.8,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(Icons.star, size: size, color: Colors.amber);
          } else if (rating > starValue - 1) {
            return Icon(Icons.star_half, size: size, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
          }
        }),
        if (showCount) ...[
          const SizedBox(width: 6),
          Text(
            '${rating.toStringAsFixed(1)} ($totalRatings)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

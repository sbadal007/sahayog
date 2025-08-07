import 'package:flutter/material.dart';
import '../models/user_rating_summary.dart';

class RatingDisplayWidget extends StatelessWidget {
  final UserRatingSummary ratingSummary;
  final bool isCompact;
  final bool showDetails;

  const RatingDisplayWidget({
    super.key,
    required this.ratingSummary,
    this.isCompact = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!ratingSummary.hasRatings) {
      return _buildNoRatings();
    }

    if (isCompact) {
      return _buildCompactRating();
    }

    return _buildDetailedRating();
  }

  Widget _buildNoRatings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'No ratings yet',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 4),
          Text(
            ratingSummary.formattedAverageRating,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber[800],
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${ratingSummary.totalRatings})',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRating() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rate, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'User Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Average rating display
          Row(
            children: [
              Text(
                ratingSummary.formattedAverageRating,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarDisplay(ratingSummary.averageRating),
                  const SizedBox(height: 4),
                  Text(
                    '${ratingSummary.totalRatings} rating${ratingSummary.totalRatings != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (showDetails && ratingSummary.totalRatings > 0) ...[
            const SizedBox(height: 16),
            _buildRatingDistribution(),
          ],
        ],
      ),
    );
  }

  Widget _buildStarDisplay(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(
          rating >= starValue ? Icons.star : 
          rating >= starValue - 0.5 ? Icons.star_half : Icons.star_border,
          size: 16,
          color: Colors.amber[700],
        );
      }),
    );
  }

  Widget _buildRatingDistribution() {
    final distribution = ratingSummary.ratingDistribution;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Rating Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final stars = 5 - index;
          final percentage = distribution[stars] ?? 0.0;
          final count = _getCountForStars(stars);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 12, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  int _getCountForStars(int stars) {
    switch (stars) {
      case 5: return ratingSummary.fiveStarCount;
      case 4: return ratingSummary.fourStarCount;
      case 3: return ratingSummary.threeStarCount;
      case 2: return ratingSummary.twoStarCount;
      case 1: return ratingSummary.oneStarCount;
      default: return 0;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RatingDialog extends StatefulWidget {
  final String requestTitle;
  final String revieweeName;
  final String reviewType; // 'helper_to_requester' or 'requester_to_helper'
  final VoidCallback? onCancel;
  final Function(double rating, String? review) onSubmit;

  const RatingDialog({
    super.key,
    required this.requestTitle,
    required this.revieweeName,
    required this.reviewType,
    this.onCancel,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  
  double _rating = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final review = _reviewController.text.trim().isEmpty 
        ? null 
        : _reviewController.text.trim();

    widget.onSubmit(_rating, review);
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starValue;
            });
            // Haptic feedback
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _rating >= starValue ? Icons.star : Icons.star_border,
              size: 40,
              color: _rating >= starValue ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  String _getRatingDescription() {
    if (_rating == 0) return 'Tap a star to rate';
    
    switch (_rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  String _getReviewHint() {
    final isHelper = widget.reviewType == 'helper_to_requester';
    if (isHelper) {
      return 'How was your experience working with ${widget.revieweeName}? Was communication clear? Payment prompt?';
    } else {
      return 'How was your experience with ${widget.revieweeName}? Was the work completed satisfactorily? Professional service?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHelper = widget.reviewType == 'helper_to_requester';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.star_rate,
                    color: Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHelper ? 'Rate Requester' : 'Rate Helper',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For: ${widget.requestTitle}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Rating section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Rate ${widget.revieweeName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStarRating(),
                    const SizedBox(height: 8),
                    Text(
                      _getRatingDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Review section
              const Text(
                'Write a Review (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: _getReviewHint(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.rate_review),
                ),
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () {
                        widget.onCancel?.call();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text('Submit Rating'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

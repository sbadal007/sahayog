import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'firebase_storage_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.size = 50.0,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure size is valid and positive, with additional validation
    final validSize = (size.isFinite && size > 0 && !size.isNaN) ? size : 50.0;

    return SizedBox(
      width: validSize,
      height: validSize,
      child: Stack(
        children: [
          Container(
            width: validSize,
            height: validSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: ClipOval(
              child: _buildAvatarContent(validSize),
            ),
          ),
          if (showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: (validSize * 0.25).clamp(8.0, 20.0),
                height: (validSize * 0.25).clamp(8.0, 20.0),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(double validSize) {
    debugPrint('UserAvatar: Checking image URL: $imageUrl');
    
    if (imageUrl != null && imageUrl!.isNotEmpty && _isValidImageUrl(imageUrl!)) {
      debugPrint('UserAvatar: Valid image URL found, using FirebaseStorageImage');
      return FirebaseStorageImage(
        imageUrl: imageUrl,
        width: validSize,
        height: validSize,
        fit: BoxFit.cover,
        errorWidget: _getPlaceholderChild(validSize),
      );
    } else {
      debugPrint('UserAvatar: Invalid or null image URL');
      return _getPlaceholderChild(validSize);
    }
  }

  bool _isValidImageUrl(String url) {
    try {
      return url.startsWith('http') && Uri.tryParse(url) != null;
    } catch (e) {
      debugPrint('UserAvatar: Invalid image URL: $e');
      return false;
    }
  }

  Widget _getPlaceholderChild(double validSize) {
    return Icon(
      Icons.person,
      size: (validSize * 0.6).clamp(16.0, 48.0),
      color: Colors.grey[600],
    );
  }
}

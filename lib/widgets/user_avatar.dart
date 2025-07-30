// filepath: c:\Users\susma\Documents\sahayog\lib\widgets\user_avatar.dart
import 'package:flutter/material.dart';

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
    final radius = (validSize / 2).clamp(8.0, 100.0); // Clamp radius to reasonable bounds

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
    final imageProvider = _getValidImageProvider();
    
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: validSize,
        height: validSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('UserAvatar: Error loading image: $error');
          return _getPlaceholderChild(validSize);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    }
    
    return _getPlaceholderChild(validSize);
  }

  ImageProvider? _getValidImageProvider() {
    try {
      if (imageUrl != null &&
          imageUrl!.isNotEmpty &&
          imageUrl!.startsWith('http') &&
          Uri.tryParse(imageUrl!) != null) {
        return NetworkImage(imageUrl!);
      }
    } catch (e) {
      debugPrint('UserAvatar: Invalid image URL: $e');
    }
    return null;
  }

  Widget _getPlaceholderChild(double validSize) {
    return Icon(
      Icons.person,
      size: (validSize * 0.6).clamp(16.0, 48.0),
      color: Colors.grey[600],
    );
  }
}
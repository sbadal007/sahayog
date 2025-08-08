import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseStorageImage extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirebaseStorageImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<FirebaseStorageImage> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    // For web, use a different approach to handle CORS
    if (kIsWeb) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl!),
            fit: widget.fit,
            onError: (error, stackTrace) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
              debugPrint('FirebaseStorageImage: Error loading image: $error');
            },
          ),
        ),
      );
    }

    // For other platforms, use the standard Image.network
    return Image.network(
      widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (_isLoading && mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return child;
        }
        return widget.placeholder ?? 
               Center(
                 child: CircularProgressIndicator(
                   value: loadingProgress.expectedTotalBytes != null
                       ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                       : null,
                 ),
               );
      },
      errorBuilder: (context, error, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        debugPrint('FirebaseStorageImage: Error loading image: $error');
        return widget.errorWidget ?? _buildDefaultError();
      },
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: (widget.width * 0.6).clamp(16.0, 48.0),
        color: Colors.grey[600],
      ),
    );
  }
}

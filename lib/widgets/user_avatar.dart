// filepath: c:\Users\susma\Documents\sahayog\lib\widgets\user_avatar.dart
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey[300],
    );
  }
}
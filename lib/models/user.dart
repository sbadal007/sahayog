// filepath: lib/models/user.dart
class User {
  final String id;
  final String username;
  final String email;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      imageUrl: json['imageUrl'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
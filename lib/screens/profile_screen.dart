import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_status_service.dart';
import '../widgets/user_status_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('ProfileScreen: No authenticated user');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('ProfileScreen: Loading data for user ${user.uid}');
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
        
      if (doc.exists && mounted) {
        final data = doc.data();
        debugPrint('ProfileScreen: User data loaded: $data');
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        debugPrint('ProfileScreen: User document does not exist, creating default');
        await _createUserDocument(user);
        // Reload after creating the document
        final newDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (newDoc.exists && mounted) {
          setState(() {
            _userData = newDoc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('ProfileScreen: Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      debugPrint('ProfileScreen: Creating user document for ${user.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email ?? '',
        'username': user.displayName ?? 'User${user.uid.substring(0, 6)}',
        'role': 'Requester', // Default role
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'profileImageUrl': null,
      }, SetOptions(merge: true));
      
      debugPrint('ProfileScreen: User document created successfully');
    } catch (e) {
      debugPrint('ProfileScreen: Error creating user document: $e');
      rethrow;
    }
  }

  Future<void> _logout() async {
    try {
      await UserStatusService().setUserOfflineOnLogout();
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('ProfileScreen: Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out')),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    final profileImageUrl = _userData?['profileImageUrl'] as String?;
    
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: profileImageUrl != null
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl == null
          ? Icon(
              Icons.person,
              size: 60,
              color: Colors.grey[600],
            )
          : null,
    );
  }

  Widget _buildVerificationBadge() {
    final isVerified = _userData?['isVerified'] ?? false;
    
    if (!isVerified) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.verified,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final username = _userData?['username'] ?? 'Unknown User';
    final email = _userData?['email'] ?? user.email ?? 'No email';
    final role = _userData?['role'] ?? 'No role';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildVerificationBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: role == 'Helper' ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Real-time status display
        UserStatusWidget(
          userId: user.uid,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 24),
                  _buildUserInfo(),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to edit profile screen
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.security),
                            title: const Text('Privacy Settings'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to privacy settings
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to help screen
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

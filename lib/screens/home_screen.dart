import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/create_request_tab.dart';
import '../widgets/view_offers_tab.dart';
import '../widgets/helper_inbox.dart';
import '../widgets/requester_inbox.dart';
import 'profile_screen.dart' hide Text, Icon;
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && mounted) {
          final userData = doc.data();
          setState(() {
            _userRole = userData?['role'] as String?;
            _isLoading = false;
            _error = null;
          });
        } else if (mounted) {
          setState(() {
            _error = 'User profile not found';
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _error = 'No authenticated user';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Error fetching user role: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading user data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAppBarTitle() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sahayog',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (userProvider.username != null)
              Text(
                'Welcome ${userProvider.username!}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileAction() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: UserAvatar(
              imageUrl: userProvider.profileImageUrl,
              size: 36,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          _buildProfileAction(),
        ],
        automaticallyImplyLeading: false,
      ),
      body: _buildTabContent(),
      bottomNavigationBar: _userRole == null
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  _buildNavItem(0, Icons.inbox, 'Inbox'),
                  if (_userRole == 'Requester')
                    _buildNavItem(1, Icons.add_circle, 'Create Request'),
                  if (_userRole == 'Helper')
                    _buildNavItem(2, Icons.list, 'View Offers'),
                ],
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user data...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchUserRole();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('Please login to continue'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    if (_userRole == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text('User role not set'),
            SizedBox(height: 8),
            Text(
              'Please contact support or try logging out and back in',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    try {
      switch (_selectedIndex) {
        case 0:
          return _userRole == 'Helper'
              ? HelperInbox(userId: user.uid)
              : RequesterInbox(userId: user.uid);
        case 1:
          return _userRole == 'Requester'
              ? const CreateRequestTab()
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Only requesters can create requests'),
                    ],
                  ),
                );
        case 2:
          return _userRole == 'Helper'
              ? const ViewOffersTab()
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Only helpers can view requests'),
                    ],
                  ),
                );
        default:
          return const Center(
            child: Text('Unknown tab selected'),
          );
      }
    } catch (e) {
      debugPrint('HomeScreen: Error building tab content: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading content: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Text('Reset to Inbox'),
            ),
          ],
        ),
      );
    }
  }
}
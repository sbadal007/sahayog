import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/create_request_tab.dart';
import '../widgets/view_offers_tab.dart';
import '../widgets/helper_inbox.dart';
import '../widgets/requester_inbox.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;

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
        if (mounted) {
          setState(() {
            _userRole = doc.data()?['role'] as String?;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sahayog'),
            Text(
              'A Smart Way to Connect Helpers and Requesters Nearby',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
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
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    switch (_selectedIndex) {
      case 0:
        if (_userRole == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _userRole == 'Helper'
            ? HelperInbox(userId: user.uid)
            : RequesterInbox(userId: user.uid);
      case 1:
        return _userRole == 'Requester'
            ? const CreateRequestTab()
            : const Center(child: Text('Only requesters can create requests'));
      case 2:
        return _userRole == 'Helper'
            ? const ViewOffersTab()
            : const Center(child: Text('Only helpers can view requests'));
      default:
        return const SizedBox();
    }
  }
}
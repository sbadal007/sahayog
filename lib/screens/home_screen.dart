import 'package:flutter/material.dart';
import '../widgets/inbox_tab.dart';
import '../widgets/create_request_tab.dart';
import '../widgets/view_offers_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            _buildNavItem(0, Icons.inbox, 'Inbox'),
            _buildNavItem(1, Icons.add_circle, 'Create Request'),
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
    switch (_selectedIndex) {
      case 0:
        return const InboxTab();
      case 1:
        return const CreateRequestTab();
      case 2:
        return const ViewOffersTab();
      default:
        return const SizedBox();
    }
  }
}
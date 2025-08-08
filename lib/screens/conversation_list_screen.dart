import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';
import '../services/error_service.dart';
import '../widgets/error_boundary.dart';
import '../widgets/index_builder.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view conversations')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: ChatIndexBuilder(
        userId: currentUser.uid,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveConversations(currentUser.uid),
            _buildArchivedConversations(currentUser.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveConversations(String userId) {
    return SafeStreamBuilder<List<Conversation>>(
      stream: ChatService.getUserConversationsStream(userId),
      location: 'ConversationListScreen.activeConversations',
      errorType: ErrorType.chat,
      onRetry: () {
        // Force rebuild by calling setState
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      },
      emptyBuilder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting when you accept or send offers!',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      builder: (context, conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start chatting when you accept or send offers!',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(conversation, userId);
          },
        );
      },
    );
  }

  Widget _buildArchivedConversations(String userId) {
    return SafeStreamBuilder<List<Conversation>>(
      stream: ChatService.getArchivedConversationsStream(userId),
      location: 'ConversationListScreen.archivedConversations',
      errorType: ErrorType.chat,
      onRetry: () {
        // Force rebuild by calling setState
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      },
      emptyBuilder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No archived conversations',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      builder: (context, conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No archived conversations',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(conversation, userId, isArchived: true);
          },
        );
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation, String currentUserId, {bool isArchived = false}) {
    final otherParticipantId = conversation.getOtherParticipantId(currentUserId);
    final unreadCount = conversation.getUnreadCountForUser(currentUserId);
    final hasUnread = unreadCount > 0;

    return FutureBuilder<String>(
      future: _getOtherParticipantName(otherParticipantId),
      builder: (context, nameSnapshot) {
        final otherParticipantName = nameSnapshot.data ?? 'User';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                otherParticipantName.isNotEmpty 
                    ? otherParticipantName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherParticipantName,
                    style: TextStyle(
                      fontWeight: hasUnread && !isArchived ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasUnread && !isArchived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isArchived)
                  const Icon(
                    Icons.archive,
                    size: 16,
                    color: Colors.grey,
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.lastMessageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread && !isArchived ? Colors.black87 : Colors.grey[600],
                    fontWeight: hasUnread && !isArchived ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: isArchived
                ? () => _showArchivedConversationDialog(conversation, otherParticipantName)
                : () => _navigateToChat(conversation, otherParticipantName),
          ),
        );
      },
    );
  }

  Future<String> _getOtherParticipantName(String userId) async {
    try {
      // Try to get user name from UserProvider first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.uid == userId) {
        return userProvider.username ?? 'User';
      }

      // If not found, fetch from Firestore
      // This is a simplified version - in production you might want to cache user names
      return 'User'; // Placeholder for now
    } catch (e) {
      return 'User';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today: show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week: show day
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older: show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _navigateToChat(Conversation conversation, String otherParticipantName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          otherParticipantName: otherParticipantName,
        ),
      ),
    );
  }

  void _showArchivedConversationDialog(Conversation conversation, String otherParticipantName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archived Conversation'),
        content: Text(
          'This conversation with $otherParticipantName is archived and read-only. '
          'You cannot send new messages to archived conversations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: conversation.id,
                    otherParticipantName: otherParticipantName,
                    isArchived: true,
                  ),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

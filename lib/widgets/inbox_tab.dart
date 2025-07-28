import 'package:flutter/material.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  final List<Map<String, String>> _messages = const [
    {
      'sender': 'John Doe',
      'message': 'I can help you with moving furniture',
      'time': '10 mins ago',
      'initials': 'JD',
    },
    {
      'sender': 'Sarah Wilson',
      'message': 'Available for evening hospital visit assistance',
      'time': '1 hour ago',
      'initials': 'SW',
    },
    {
      'sender': 'Mike Brown',
      'message': 'Can provide transportation tomorrow morning',
      'time': '2 hours ago',
      'initials': 'MB',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _messages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(message['initials']!),
            ),
            title: Text(message['sender']!),
            subtitle: Text(message['message']!),
            trailing: Text(message['time']!),
            onTap: () {},
          ),
        );
      },
    );
  }
}

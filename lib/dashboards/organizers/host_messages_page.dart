import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class HostMessagesPage extends StatefulWidget {
  const HostMessagesPage({super.key});

  @override
  State<HostMessagesPage> createState() => _HostMessagesPageState();
}

class _HostMessagesPageState extends State<HostMessagesPage> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://i.pravatar.cc/150?u=sarah',
      'lastMessage': 'I have checked the requirements...',
      'time': '12:45 PM',
      'unread': true,
      'isOnline': true,
    },
    {
      'name': 'Michael Chen',
      'avatar': 'https://i.pravatar.cc/150?u=michael',
      'lastMessage': 'The venue contract is ready.',
      'time': 'Yesterday',
      'unread': false,
      'isOnline': false,
    },
    {
      'name': 'Emily Davis',
      'avatar': 'https://i.pravatar.cc/150?u=emily',
      'lastMessage': 'See you at the site visit tomorrow.',
      'time': '2 days ago',
      'unread': false,
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search managers...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          name: conversation['name'],
                          avatar: conversation['avatar'],
                          isOnline: conversation['isOnline'],
                        ),
                      ),
                    );
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(conversation['avatar']),
                      ),
                      if (conversation['isOnline'])
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        conversation['time'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    conversation['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conversation['unread'] ? Colors.black87 : Colors.grey,
                      fontWeight: conversation['unread'] ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

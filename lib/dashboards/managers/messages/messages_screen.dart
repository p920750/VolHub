import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/manager_drawer.dart';
import 'widgets/chat_list_item.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for "Direct Messages"
    final mockHosts = [
      {'id': '1', 'name': 'Sarah Jenkins', 'lastMessage': 'See you tomorrow!', 'time': '10:30 AM', 'unread': 2, 'avatar': 'https://i.pravatar.cc/150?img=1'},
      {'id': '2', 'name': 'David Chen', 'lastMessage': 'Thanks for the opportunity.', 'time': 'Yesterday', 'unread': 0, 'avatar': 'https://i.pravatar.cc/150?img=2'},
    ];

    // Mock Data for "Groups"
    final mockGroups = [
      {'id': '3', 'name': 'Photography Team', 'lastMessage': 'Meeting at 5 PM', 'time': '11:45 AM', 'unread': 5, 'memberCount': 14, 'isGroup': true},
      {'id': '4', 'name': 'Logistics Crew', 'lastMessage': 'All equipment loaded.', 'time': 'Yesterday', 'unread': 0, 'memberCount': 22, 'isGroup': true},
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.midnightBlue,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(icon: const Icon(Icons.search, color: Colors.white70), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.white70), onPressed: () {}),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.mintIce,
            labelColor: AppColors.mintIce,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Direct'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        drawer: const ManagerDrawer(currentRoute: '/manager-messages'),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.midnightBlue,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: TabBarView(
            children: [
              _buildChatList(context, mockHosts),
              _buildChatList(context, mockGroups),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppColors.midnightBlue,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New Message',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.mintIce,
                        child: Icon(Icons.person_add, color: AppColors.midnightBlue),
                      ),
                      title: const Text('New Chat', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.mintIce,
                        child: Icon(Icons.group_add, color: AppColors.midnightBlue),
                      ),
                      title: const Text('New Group', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.mintIce,
                        child: Icon(Icons.campaign, color: AppColors.midnightBlue),
                      ),
                      title: const Text('New Announcement', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          },
          backgroundColor: AppColors.mintIce,
          child: const Icon(Icons.message, color: AppColors.midnightBlue),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<Map<String, dynamic>> chats) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.white10,
        indent: 80,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          name: chat['name'],
          lastMessage: chat['lastMessage'],
          time: chat['time'],
          unreadCount: chat['unread'],
          avatarUrl: chat.containsKey('avatar') ? chat['avatar'] : null,
          isGroup: chat['isGroup'] ?? false,
          memberCount: chat['memberCount'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(chatId: chat['id'] as String),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../volunteer_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/chat_service.dart';
import 'chat_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerChatPage extends StatefulWidget {
  const VolunteerChatPage({Key? key}) : super(key: key);

  @override
  State<VolunteerChatPage> createState() => _VolunteerChatPageState();
}

class _VolunteerChatPageState extends State<VolunteerChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewChatSheet(chatService: _chatService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VolunteerColors.background,
      appBar: AppBar(
        backgroundColor: VolunteerColors.card,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: VolunteerColors.accentSoftBlue,
          labelColor: VolunteerColors.accentSoftBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Single'),
            Tab(text: 'Group'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList('single'),
          _buildChatList('group'),
          _buildChatList('community'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: VolunteerColors.accentSoftBlue,
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: _showNewChatDialog,
      ),
    );
  }

  Widget _buildChatList(String type) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRooms = snapshot.data ?? [];
        final filteredRooms = allRooms.where((r) => r['type'] == type).toList();

        if (filteredRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'single' ? Icons.person_outline : Icons.group_outlined,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No $type chats yet',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredRooms.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            final messages = room['messages'] as List?;
            final lastMessage = messages != null && messages.isNotEmpty
                ? messages[0]['content']
                : 'No messages yet';
            final timeStr = messages != null && messages.isNotEmpty
                ? messages[0]['created_at']
                : '';
            
            String displayName = room['name'] ?? 'Chat';
            String? avatarUrl;

            // For single chats, find the other participant's name
            if (type == 'single') {
              final participants = room['chat_room_participants'] as List?;
              if (participants != null) {
                final other = participants.firstWhere(
                  (p) => p['user_id'] != _currentUserId,
                  orElse: () => null,
                );
                if (other != null && other['users'] != null) {
                  displayName = other['users']['full_name'] ?? 'User';
                  avatarUrl = other['users']['profile_photo'];
                }
              }
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      roomId: room['id'],
                      chatName: displayName,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: VolunteerColors.accentSoftBlue.withOpacity(0.2),
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                        ? Icon(
                            type == 'single'
                                ? FontAwesomeIcons.user
                                : (type == 'group' ? FontAwesomeIcons.users : FontAwesomeIcons.city),
                            color: VolunteerColors.accentSoftBlue,
                            size: 24,
                          )
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                timeStr.isNotEmpty ? timeStr.substring(11, 16) : '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  final ChatService chatService;
  const _NewChatSheet({required this.chatService});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _search(String q) async {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    final users = await widget.chatService.searchUsers(q);
    setState(() {
      _results = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: VolunteerColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search volunteers...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: VolunteerColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: VolunteerColors.accentSoftBlue.withOpacity(0.2),
                        backgroundImage: user['profile_photo'] != null ? NetworkImage(user['profile_photo']) : null,
                        child: user['profile_photo'] == null ? const Icon(Icons.person, color: VolunteerColors.accentSoftBlue) : null,
                      ),
                      title: Text(user['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(user['role'] ?? '', style: const TextStyle(color: Colors.grey)),
                      onTap: () async {
                        final roomId = await widget.chatService.createSingleChat(user['id']);
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailPage(
                              roomId: roomId,
                              chatName: user['full_name'] ?? 'Chat',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

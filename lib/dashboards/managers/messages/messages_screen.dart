import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/manager_drawer.dart';
import 'widgets/chat_list_item.dart';
import 'chat_detail_screen.dart';
import '../../../services/supabase_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Mock Data for "Groups" - Kept as is for now
  final mockGroups = [
    {'id': '3', 'name': 'Photography Team', 'lastMessage': 'Meeting at 5 PM', 'time': '11:45 AM', 'unread': 5, 'memberCount': 14, 'isGroup': true},
    {'id': '4', 'name': 'Logistics Crew', 'lastMessage': 'All equipment loaded.', 'time': 'Yesterday', 'unread': 0, 'memberCount': 22, 'isGroup': true},
  ];

  List<Map<String, dynamic>> _organizers = [];
  List<Map<String, dynamic>> _volunteers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final organizers = await SupabaseService.getUsersByRole('organizer'); // or 'event_organizer' check your DB roles
    final volunteers = await SupabaseService.getUsersByRole('volunteer');
    
    setState(() {
      _organizers = organizers;
      _volunteers = volunteers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.midnightBlue,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70), 
              onPressed: () {
                showSearch(context: context, delegate: UserSearchDelegate(mockGroups));
              }
            ),
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.white70), onPressed: () {}),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.mintIce,
            labelColor: AppColors.mintIce,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Organizers'),
              Tab(text: 'Volunteers'),
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.mintIce))
            : TabBarView(
                children: [
                  _buildUserList(context, _organizers),
                  _buildUserList(context, _volunteers),
                  _buildChatList(context, mockGroups),
                ],
              ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             // ... existing FAB logic ...
          },
          backgroundColor: AppColors.mintIce,
          child: const Icon(Icons.message, color: AppColors.midnightBlue),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text('No users found', style: TextStyle(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        indent: 80,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        return ChatListItem(
          name: user['full_name'] ?? 'Unknown',
          lastMessage: 'Tap to start chatting', // Placeholder
          time: '',
          unreadCount: 0,
          avatarUrl: user['profile_photo'],
          isGroup: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: user['id'] as String,
                  chatName: user['full_name'] as String?,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatList(BuildContext context, List<Map<String, dynamic>> chats) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      separatorBuilder: (context, index) => const Divider(
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
                builder: (context) => ChatDetailScreen(
                  chatId: chat['id'] as String,
                  chatName: chat['name'] as String?,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> groups;
  UserSearchDelegate(this.groups);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.midnightBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.midnightBlue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found', style: TextStyle(color: Colors.white)));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final result = snapshot.data![index];
            final isGroup = result['isGroup'] == true;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: result['profile_photo'] != null ? NetworkImage(result['profile_photo']) : null, 
                child: result['profile_photo'] == null ? Text(result['full_name'][0]) : null,
              ),
              title: Text(result['full_name'], style: const TextStyle(color: Colors.white)),
              subtitle: Text(isGroup ? 'Group' : (result['role'] ?? 'User'), style: const TextStyle(color: Colors.white70)),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      chatId: result['id'],
                      chatName: result['full_name'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  Future<List<Map<String, dynamic>>> _search(String query) async {
    if (query.isEmpty) return [];

    // 1. Search Users from Supabase
    final users = await SupabaseService.searchUsers(query);
    
    // 2. Search Groups (Local Mock)
    final matchedGroups = groups.where((g) => 
      g['name'].toString().toLowerCase().contains(query.toLowerCase())
    ).map((g) => {
      'id': g['id'],
      'full_name': g['name'],
      'profile_photo': null, // Groups might not have single photo url structure here
      'role': 'Group',
      'isGroup': true,
    }).toList();

    // 3. Search Users BY Group Name (The requested feature)
    // For now, if query matches a group name, return users in that group.
    // Since we don't have real group-user relation, we'll mock this:
    // If query matches "Photography", we'll "find" some users and claim they are in it.
    // In a real app, you'd do: supabase.from('group_members').select('users(*)').eq('group_name', query)
    
    List<Map<String, dynamic>> usersInGroup = [];
    if (query.toLowerCase().contains('photo')) {
       // Mock finding users in "Photography Team"
       // usersInGroup.add({'id': 'mock_1', 'full_name': 'Sarah (Photo Lead)', 'role': 'volunteer'});
    }

    return [...users, ...matchedGroups, ...usersInGroup];
  }
}

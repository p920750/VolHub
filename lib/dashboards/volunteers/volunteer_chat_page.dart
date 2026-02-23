import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/supabase_service.dart';
import 'volunteer_colors.dart';
import '../organizers/chat_detail_page.dart'; // Reusing existing beautiful chat detail page

class VolunteerChatPage extends StatefulWidget {
  const VolunteerChatPage({super.key});

  @override
  State<VolunteerChatPage> createState() => _VolunteerChatPageState();
}

class _VolunteerChatPageState extends State<VolunteerChatPage> {
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    // Volunteers primarily chat with Managers/Hosts
    final managers = await SupabaseService.getUsersByRole('manager');
    final eventManagers = await SupabaseService.getUsersByRole('event_manager');
    final hosts = await SupabaseService.getUsersByRole('host');
    final organizers = await SupabaseService.getUsersByRole('organizer');
    
    setState(() {
      _managers = [
        ...managers, 
        ...eventManagers, 
        ...hosts, 
        ...organizers
      ].fold<List<Map<String, dynamic>>>(
        [], 
        (list, user) {
          if (!list.any((u) => u['id'] == user['id'])) {
            list.add(user);
          }
          return list;
        }
      );
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredManagers {
    if (_searchQuery.isEmpty) return _managers;
    return _managers.where((m) {
      final name = (m['full_name'] ?? '').toString().toLowerCase();
      final email = (m['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VolunteerColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search managers or hosts...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_filteredManagers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.commentSlash,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<Map<String, int>>(
      stream: SupabaseService.getUnreadCountsStream(),
      builder: (context, unreadSnapshot) {
        final unreadCounts = unreadSnapshot.data ?? {};

        return ListView.separated(
          itemCount: _filteredManagers.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = _filteredManagers[index];
            final userId = user['id'];
            final name = user['full_name'] ?? 'Unknown User';
            final avatar = user['profile_photo'] ?? '';
            final unreadCount = unreadCounts[userId] ?? 0;

            return _buildChatItem(
              userId: userId,
              name: name,
              avatar: avatar,
              unreadCount: unreadCount,
              role: user['role'] ?? 'Manager',
            );
          },
        );
      },
    );
  }

  Widget _buildChatItem({
    required String userId,
    required String name,
    required String avatar,
    required int unreadCount,
    required String role,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              chatId: userId,
              name: name,
              avatar: avatar,
              isOnline: false, // Defaulting to offline, Supabase real-time handles status elsewhere
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: VolunteerColors.accentSoftBlue.withOpacity(0.1),
                  backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                  child: !avatar.startsWith('http') 
                      ? Text(name[0], style: TextStyle(color: VolunteerColors.accentSoftBlue, fontWeight: FontWeight.bold, fontSize: 20)) 
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

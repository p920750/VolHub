import 'package:flutter/material.dart';
import 'chat_detail_page.dart';
import '../../../services/supabase_service.dart';

class HostMessagesPage extends StatefulWidget {
  const HostMessagesPage({super.key});

  @override
  State<HostMessagesPage> createState() => _HostMessagesPageState();
}

class _HostMessagesPageState extends State<HostMessagesPage> {
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  Future<void> _fetchManagers() async {
    setState(() => _isLoading = true);
    // Fetch only managers assigned to this host's events
    final managers = await SupabaseService.getAssignedManagersForHost();
    
    setState(() {
      _managers = managers;
      _isLoading = false;
    });
  }

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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF001529)))
              : _managers.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No managers found', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : StreamBuilder<Map<String, int>>(
                    stream: SupabaseService.getUnreadCountsStream(),
                    builder: (context, unreadSnapshot) {
                      final unreadCounts = unreadSnapshot.data ?? {};
                      
                      return ListView.separated(
                        itemCount: _managers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                        itemBuilder: (context, index) {
                          final manager = _managers[index];
                          final managerId = manager['id'];
                          final name = manager['full_name'] ?? 'Unknown Manager';
                          final avatar = manager['profile_photo'] ?? '';
                          final isOnline = manager['is_online'] ?? false;
                          final unreadCount = unreadCounts[managerId] ?? 0;
                          
                          return ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailPage(
                                    chatId: managerId,
                                    name: name,
                                    avatar: avatar,
                                    isOnline: isOnline,
                                  ),
                                ),
                              );
                              // Refresh counts if needed, though stream should handle it
                            },
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                                  child: !avatar.startsWith('http') ? Text(name[0]) : null,
                                ),
                                if (isOnline)
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
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001529),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              unreadCount > 0 ? '$unreadCount new messages' : 'Tap to start chatting',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0 ? const Color(0xFF001529) : Colors.grey,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
          ),
        ],
      ),
    );
  }
}

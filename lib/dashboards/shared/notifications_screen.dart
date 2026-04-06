import 'package:flutter/material.dart';
import 'package:main_volhub/services/notification_service.dart';
import 'package:main_volhub/services/supabase_service.dart';
import 'package:main_volhub/services/host_service.dart';
import 'package:main_volhub/dashboards/organizers/event_detail_page.dart';
import 'package:main_volhub/dashboards/managers/proposals/proposal_details_screen.dart';
import 'package:main_volhub/dashboards/organizers/chat_detail_page.dart';
import 'package:main_volhub/dashboards/managers/messages/chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selectedIds.length} selected notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final idsToDelete = _selectedIds.toList();
      _clearSelection();
      await NotificationService.deleteMultipleNotifications(idsToDelete);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Delete all notifications? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.deleteAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
          : null,
        title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'Notifications'),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelected,
              tooltip: 'Delete selected',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () async {
                await NotificationService.markAllAsRead();
              },
              tooltip: 'Mark all as read',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearAll,
              tooltip: 'Clear all notifications',
            ),
          ],
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final id = notification['id'].toString();
              final isRead = notification['is_read'] ?? false;
              final isSelected = _selectedIds.contains(id);
              
              String timeAgo = '';
              if (notification['created_at'] != null) {
                try {
                  final date = DateTime.parse(notification['created_at']);
                  timeAgo = timeago.format(date);
                } catch (_) {}
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isSelected 
                  ? Colors.blue.withValues(alpha: 0.1)
                  : (isRead ? null : Colors.blue.withValues(alpha: 0.05)),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: isRead ? Colors.grey[200] : const Color(0xFFE3F2FD),
                      child: Icon(
                        _getIconForType(notification['type']),
                        color: isRead ? Colors.grey[600] : const Color(0xFF1E88E5),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: isRead ? Colors.black87 : Colors.black,
                        ),
                      ),
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRead ? Colors.grey : const Color(0xFF1E88E5),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    notification['body'] ?? '',
                    style: TextStyle(
                      color: isRead ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                trailing: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(id),
                      shape: const CircleBorder(),
                    )
                  : (isRead 
                      ? null
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: Colors.blue),
                          ],
                        )),
                onLongPress: () => _toggleSelection(id),
                onTap: () async {
                  if (_isSelectionMode) {
                    _toggleSelection(id);
                    return;
                  }

                  if (!isRead) {
                    await NotificationService.markAsRead(id);
                    if (!mounted) return;
                  }
                  
                  final eventId = notification['event_id'];
                  final type = notification['type']?.toString().toLowerCase();

                  if (type == 'chat') {
                    // Logic for chat navigation
                    try {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(child: CircularProgressIndicator());
                        },
                      );

                      final userData = await SupabaseService.getUserFromUsersTable();
                      if (!mounted) return;
                      final role = userData?['role'] ?? 'host';
                      
                      if (eventId != null) {
                        final eventResponse = await SupabaseService.client
                            .from('events')
                            .select('*, host:users!user_id(id, full_name, profile_photo)')
                            .eq('id', eventId)
                            .maybeSingle();

                        if (context.mounted) Navigator.pop(context);

                        if (eventResponse != null && context.mounted) {
                          if (role == 'host' || role == 'organizer') {
                             Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(
                                  chatId: eventId,
                                  name: eventResponse['name'] ?? 'Group Chat',
                                  avatar: eventResponse['image_url'] ?? '',
                                  isOnline: true,
                                  eventId: eventId,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  chatId: eventId,
                                  chatName: eventResponse['name'],
                                  avatarUrl: eventResponse['image_url'],
                                  isGroup: true,
                                  eventId: eventId,
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                         if (context.mounted) Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open chat.')),
                        );
                      }
                    }
                    return;
                  }

                  if (eventId != null) {
                    try {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(child: CircularProgressIndicator());
                        },
                      );

                      final eventResponse = await SupabaseService.client
                          .from('events')
                          .select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)')
                          .eq('id', eventId)
                          .maybeSingle();

                      if (!context.mounted) return;
                      Navigator.pop(context); // Close loading dialog

                      if (eventResponse != null && context.mounted) {
                        final userData = await SupabaseService.getUserFromUsersTable();
                        if (!context.mounted) return;
                        final role = userData?['role'] ?? 'host';

                        final Map<String, dynamic> eventDetails = Map<String, dynamic>.from(eventResponse);
                        final hostData = eventDetails['host'] as Map<String, dynamic>?;
                        
                        eventDetails['host'] = hostData ?? {'full_name': eventDetails['host_name'] ?? 'Organizer'};
                        
                        try {
                          eventDetails['registration_deadline_formatted'] = HostService.formatDeadlineForMyEvents(eventDetails['registration_deadline']);
                        } catch (e) {
                           eventDetails['registration_deadline_formatted'] = 'Not Set';
                        }
                        
                        try {
                           final dateInput = eventDetails['date'];
                           final timeStr = eventDetails['time'];
                           final DateTime date = dateInput is DateTime ? dateInput : DateTime.parse(dateInput.toString());
                           final day = date.day.toString().padLeft(2, '0');
                           final month = date.month.toString().padLeft(2, '0');
                           final year = date.year;
                           final String time = (timeStr == null || timeStr == 'TBD' || timeStr.toString().isEmpty) ? 'TBD' : timeStr.toString();
                           eventDetails['date_time_formatted'] = '$day/$month/$year at $time';
                        } catch(e) {
                           eventDetails['date_time_formatted'] = '${eventDetails['date']} at ${eventDetails['time'] ?? "TBD"}';
                        }
                        
                        eventDetails['title'] = eventDetails['name'];
                        eventDetails['imageUrl'] = eventDetails['image_url'];
                        eventDetails['status'] = (eventDetails['status'] ?? 'pending').toString().toLowerCase();

                         if (role == 'host' || role == 'organizer') {
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailPage(event: eventDetails),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProposalDetailsScreen(event: eventDetails),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                         if (Navigator.canPop(context)) {
                           Navigator.pop(context); 
                         }
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Could not load event details.')),
                         );
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications;
    switch (type.toLowerCase()) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'proposal':
        return Icons.assignment_outlined;
      case 'acceptance':
        return Icons.check_circle_outline;
      case 'application':
        return Icons.person_add_outlined;
      case 'withdrawal':
        return Icons.exit_to_app_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

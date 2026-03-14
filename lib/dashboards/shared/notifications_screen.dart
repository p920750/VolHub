import 'package:flutter/material.dart';
import 'package:main_volhub/services/notification_service.dart';
import 'package:main_volhub/services/supabase_service.dart';
import 'package:main_volhub/services/host_service.dart';
import 'package:main_volhub/dashboards/organizers/event_detail_page.dart';
import 'package:main_volhub/dashboards/managers/proposals/proposal_details_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await NotificationService.markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
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
              final isRead = notification['is_read'] ?? false;
              
              String timeAgo = '';
              if (notification['created_at'] != null) {
                try {
                  final date = DateTime.parse(notification['created_at']);
                  timeAgo = timeago.format(date);
                } catch (_) {}
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isRead ? null : Colors.blue.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey[200] : const Color(0xFFE3F2FD),
                  child: Icon(
                    _getIconForType(notification['type']),
                    color: isRead ? Colors.grey[600] : const Color(0xFF1E88E5),
                  ),
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
                trailing: isRead 
                  ? null
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.blue),
                      ],
                    ),
                onTap: () async {
                  if (!isRead) {
                    await NotificationService.markAsRead(notification['id']);
                  }
                  
                  final eventId = notification['event_id'];
                  if (eventId != null) {
                    try {
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

                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                      }

                      if (eventResponse != null && context.mounted) {
                        final user = SupabaseService.currentUser;
                        final userData = await SupabaseService.getUserFromUsersTable();
                        final role = userData?['role'] ?? 'host';

                        final Map<String, dynamic> eventDetails = Map<String, dynamic>.from(eventResponse);
                        final hostData = eventDetails['host'] as Map<String, dynamic>?;
                        
                        eventDetails['host'] = hostData ?? {'full_name': eventDetails['host_name'] ?? 'Organizer'};
                        
                        try {
                          eventDetails['registration_deadline_formatted'] = HostService.formatDeadlineForMyEvents(eventDetails['registration_deadline']);
                        } catch (e) {
                           eventDetails['registration_deadline_formatted'] = 'Not Set';
                        }
                        
                        // Formatting date correctly
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
                          // Manager navigation
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
                         // Ensure loading dialog is closed on error
                         if (Navigator.canPop(context)) { // rudimentary check
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

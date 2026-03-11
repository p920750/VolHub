import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/manager_drawer.dart';
import '../core/theme.dart';
import '../post_events/post_events_screen.dart';
import '../../../services/event_manager_service.dart';
import '../../../services/host_service.dart';
import '../../../../widgets/safe_avatar.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  Color _getSlotsColor(int available, int total) {
    if (total <= 0) return Colors.red;
    final ratio = available / total;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('events')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
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
      try {
        await Supabase.instance.client.from('events').delete().eq('id', eventId);
        _fetchMyEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMyEvents),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-my-events'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('You haven\'t created any events yet.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/manager-post-events'),
                        child: const Text('Post First Event'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event['image_url'] != null && event['image_url'].toString().isNotEmpty)
                            Image.network(
                              event['image_url'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            ListTile(
                              title: Text(event['name'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${event['date']?.split('T')[0] ?? 'TBD'}'),
                                  if (event['role_description'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(event['role_description'], style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        event['payment_type'] == 'Paid' ? Icons.payment : Icons.volunteer_activism, 
                                        size: 14, 
                                        color: event['payment_type'] == 'Paid' ? Colors.green : Colors.grey
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        event['payment_type'] == 'Paid' 
                                            ? 'Paid (${event['payment_amount'] ?? ''})' 
                                            : 'Unpaid',
                                        style: TextStyle(
                                          color: event['payment_type'] == 'Paid' ? Colors.green[700] : Colors.grey[700], 
                                          fontSize: 12,
                                          fontWeight: event['payment_type'] == 'Paid' ? FontWeight.w600 : FontWeight.normal
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEventStatusBadge(event),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostEventsScreen(editEvent: event),
                                    ),
                                  ).then((_) => _fetchMyEvents());
                                } else if (value == 'delete') {
                                  _deleteEvent(event['id'].toString());
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete')])),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${(event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0)} slots left', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getSlotsColor(
                                      (event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0), 
                                      event['volunteers_needed'] ?? 1
                                    )
                                  ),
                                ),
                                  const Spacer(),
                                  if (_canMarkAsFinished(event))
                                    ElevatedButton(
                                      onPressed: () => _showCompletionDialog(event),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      child: const Text('Mark as Finished', style: TextStyle(fontSize: 12)),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () {
                                        _showApplicants(event);
                                      },
                                      child: const Text('View Applicants'),
                                    ),
                                ],
                              ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/manager-post-events').then((_) => _fetchMyEvents()),
        backgroundColor: AppColors.midnightBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showApplicants(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Applicants for ${event['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: EventManagerService.getApplicantsStream(event['id'].toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No applicants yet.'));
                    }
                    
                    final applicants = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: applicants.length,
                      itemBuilder: (context, index) {
                        final app = applicants[index];
                        final volunteer = app['volunteer'] as Map<String, dynamic>?;
                        if (volunteer == null) return const SizedBox.shrink();

                        final String status = app['status'] ?? 'pending';
                        final bool isAccepted = status == 'accepted';
                        final bool isRejected = status == 'rejected';

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/volunteer-public-profile',
                              arguments: {'volunteerId': volunteer['id'].toString()},
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SafeAvatar(
                                    imageUrl: volunteer['profile_photo'] ?? 'https://i.pravatar.cc/150?u=${volunteer['id']}',
                                    name: volunteer['full_name'] ?? 'Unknown Volunteer',
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volunteer['full_name'] ?? 'Unknown Volunteer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          volunteer['email'] ?? '',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Moved status badge to the top/right of the card for more prominence
                                  if (isAccepted || isRejected || status == 'withdrawn')
                                    _buildLargeStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isAccepted)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Text('Volunteer Joined', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              if (!isAccepted && !isRejected) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleRejectVolunteer(event['id'].toString(), volunteer['id'].toString()),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleAcceptVolunteer(event['id'].toString(), volunteer['id'].toString()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.midnightBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                            ],
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
        ),
      ),
    );
  }

  Future<void> _handleAcceptVolunteer(String eventId, String volunteerId) async {
    try {
      await EventManagerService.acceptVolunteer(eventId, volunteerId);
      if (mounted) {
        _fetchMyEvents(); // Refresh UI to update the slots count
        _showSuccessDialog('Volunteer Accepted', 'The volunteer has been successfully joined to the event.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnightBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Great!'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRejectVolunteer(String eventId, String volunteerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Volunteer'),
        content: const Text('Are you sure you want to reject this volunteer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EventManagerService.rejectVolunteer(eventId, volunteerId);
        if (mounted) {
          _fetchMyEvents(); // Refresh UI here as well just in case
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer rejected.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildLargeStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'APPROVED';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'REJECTED';
        break;
      case 'withdrawn':
        color = Colors.grey;
        label = 'WITHDRAWN';
        break;
      default:
        color = Colors.orange;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEventStatusBadge(Map<String, dynamic> event) {
    final status = HostService.getEventDynamicStatus(event);
    final color = HostService.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _canMarkAsFinished(Map<String, dynamic> event) {
    final status = event['status']?.toString().toLowerCase() ?? 'pending';
    if (status == 'finished' || status == 'completed') return false;

    final dynamicStatus = HostService.getEventDynamicStatus(event);
    // Allow if "In Progress" or if assigned
    return dynamicStatus == 'In Progress' || dynamicStatus == 'Assigned manager';
  }

  void _showCompletionDialog(Map<String, dynamic> event) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Event as Finished'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please list the tasks or milestones completed during this event:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter completion notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter completion notes')),
                );
                return;
              }
              
              Navigator.pop(context);
              _handleMarkAsFinished(event['id'].toString(), notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit & Finish'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkAsFinished(String eventId, String notes) async {
    setState(() => _isLoading = true);
    try {
      await EventManagerService.markEventAsFinished(eventId, notes);
      await _fetchMyEvents();
      if (mounted) {
        _showSuccessDialog('Event Finished', 'Your completion report has been sent to the organizer for verification.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

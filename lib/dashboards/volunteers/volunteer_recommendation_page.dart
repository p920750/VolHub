import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'volunteer_colors.dart';
import '../../services/event_manager_service.dart';

class VolunteerRecommendationPage extends StatefulWidget {
  const VolunteerRecommendationPage({super.key});

  @override
  State<VolunteerRecommendationPage> createState() => _VolunteerRecommendationPageState();
}

class _VolunteerRecommendationPageState extends State<VolunteerRecommendationPage> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _volunteerType = 'Loading...';
  Map<String, String> _userApplications = {}; // eventId -> status

  @override
  void initState() {
    super.initState();
    _fetchRecommendedEvents();
    _fetchUserApplications();
  }

  Future<void> _fetchUserApplications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('event_applications')
          .select('event_id, status')
          .eq('volunteer_id', user.id);

      if (mounted) {
        setState(() {
          _userApplications = {
            for (var app in response as List) 
              app['event_id'].toString(): app['status'].toString()
          };
        });
      }
    } catch (e) {
      debugPrint('Error fetching user applications: $e');
    }
  }

  Future<void> _fetchRecommendedEvents() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch user to see if they are 'inexperienced' or 'experienced'
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('volunteer_type')
          .eq('id', user.id)
          .single();
          
      final volunteerType = userResponse['volunteer_type'] as String?;
      if (mounted) setState(() => _volunteerType = volunteerType ?? 'Unknown');

      // 2. Call the appropriate Hybrid Recommendation RPC
      List<dynamic> rpcResponse = [];
      if (volunteerType == 'inexperienced') {
        rpcResponse = await Supabase.instance.client.rpc(
          'recommend_events_for_inexperienced_volunteer',
          params: {'p_user_id': user.id},
        );
      } else {
        // Defaults to experienced logic
        rpcResponse = await Supabase.instance.client.rpc(
          'recommend_events_for_experienced_volunteer',
          params: {'p_user_id': user.id},
        );
      }

      // 3. Process the response
      final recommendedEvents = List<Map<String, dynamic>>.from(rpcResponse);
      
      // Filter out filled events
      final openEvents = recommendedEvents.where((event) {
        final needed = (event['volunteers_needed'] as int?) ?? 0;
        final current = (event['current_volunteers_count'] as int?) ?? 0;
        return current < needed;
      }).toList();

      // Enrich with manager info for UI
      final enrichedEvents = await _enrichEventsWithManager(openEvents);

      if (mounted) {
        setState(() {
          _events = enrichedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recommended events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _enrichEventsWithManager(List<Map<String, dynamic>> eventList) async {
    try {
      final managerIds = eventList.map((e) => e['user_id'] ?? e['manager_id']).toSet().toList();
      if (managerIds.isEmpty) return eventList;

      final managersResponse = await Supabase.instance.client
          .from('users')
          .select('id, full_name, company_name, company_location, profile_photo')
          .inFilter('id', managerIds);

      final managerMap = {for (var m in managersResponse) m['id']: m};

      return eventList.map((event) {
        final managerId = event['user_id'] ?? event['manager_id'];
        final managerData = managerMap[managerId];
        return {
          ...event,
          'manager': managerData,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error enriching events: $e');
      return eventList;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
  Color _getSlotsColor(int available, int total) {
    if (total == 0) return Colors.grey;
    final ratio = available / total;
    if (ratio <= 0.2) return Colors.red;
    if (ratio <= 0.5) return Colors.orange;
    return Colors.green;
  }

  Future<void> _registerForEvent(Map<String, dynamic> event) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to register')));
      return;
    }

    try {
      final String? assignedManager = event['assigned_manager_id']?.toString() ?? event['manager_id']?.toString();
      final String managerId = assignedManager != null && assignedManager.isNotEmpty 
          ? assignedManager 
          : event['user_id'].toString();

      await Supabase.instance.client.from('event_applications').insert({
        'event_id': event['id'],
        'manager_id': managerId,
        'volunteer_id': user.id,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully!')));
      _fetchUserApplications(); // Refresh application statuses
    } catch (e) {
      debugPrint('Error registering for event: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  Future<void> _handleBackOut(Map<String, dynamic> event) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Back Out from Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to back out? Please provide a reason to the manager.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., Unforeseen circumstances',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Back Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (reasonController.text.trim().isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      try {
        await EventManagerService.backOutFromEvent(
          event['id'].toString(),
          user.id,
          reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully backed out.')));
          _fetchUserApplications();
        }
      } catch (e) {
        debugPrint('Error backing out: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'withdrawn':
        color = Colors.grey;
        label = 'Withdrawn';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildApplyButton(Map<String, dynamic> event) {
    final status = _userApplications[event['id'].toString()];
    
    if (status != null) {
      if (status == 'withdrawn' || status == 'rejected') {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(status == 'withdrawn' ? 'Withdrawn' : 'Rejected', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      }
      if (status == 'accepted') {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _handleBackOut(event),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red[200]!)),
            ),
            child: const Text('Back Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[100],
              foregroundColor: Colors.orange[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 18),
                SizedBox(width: 8),
                Text('Application Pending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _registerForEvent(event),
        style: ElevatedButton.styleFrom(
          backgroundColor: VolunteerColors.primaryNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final manager = event['manager'] as Map<String, dynamic>?;
    final companyName = manager?['company_name'] ?? manager?['full_name'] ?? 'Unknown Organizer';
    final isPaid = event['payment_type'] == 'Paid';
    final paymentAmount = event['payment_amount'] ?? '';
    final paymentType = event['payment_type']?.toString() ?? 'Unpaid';
    final certificateProvided = event['certificate_provided'] == true;
    final foodProvided = event['food_provided'] == true;
    
    final skillsRequired = (event['skills_required'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final roleDescription = event['role_description'] ?? 'No role description provided.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['name'] ?? 'Event Details', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                        const SizedBox(height: 8),
                        Text('by $companyName', style: TextStyle(color: VolunteerColors.accentSoftBlue, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (_userApplications[event['id'].toString()] != null)
                    _buildStatusBadge(_userApplications[event['id'].toString()]!),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildDetailRow(Icons.calendar_today, 'Date & Time', _formatDate(event['date'] ?? '')),
              _buildDetailRow(Icons.location_on, 'Location', event['location'] ?? 'Remote'),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.group, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Slots', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Text(
                          '${(event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0)} remaining', 
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                            color: _getSlotsColor(
                              (event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0), 
                              event['volunteers_needed'] ?? 1
                            ),
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (isPaid)
                _buildDetailRow(Icons.payment, 'Compensation', '$paymentType ($paymentAmount)')
              else
                _buildDetailRow(Icons.card_giftcard, 'Compensation', 'Unpaid Volunteering'),
                
              _buildDetailRow(
                Icons.emoji_events, 
                'Certificate', 
                certificateProvided ? 'Provided upon completion' : 'Not provided'
              ),
              _buildDetailRow(
                Icons.restaurant, 
                'Food', 
                foodProvided ? 'Provided during event' : 'Not provided'
              ),
              
              const Divider(height: 48),
              
              const Text('Role Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(roleDescription, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
              const SizedBox(height: 32),
              
              const Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(event['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
              const SizedBox(height: 32),
              
              if (skillsRequired.isNotEmpty) ...[
                const Text('Skills Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skillsRequired.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(skill, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 32),
              ],
              
              if ((event['categories'] as List? ?? []).isNotEmpty) ...[
                const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (event['categories'] as List? ?? []).map((cat) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(cat.toString(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 48),
              ],
              
              _buildApplyButton(event),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VolunteerColors.background,
      appBar: AppBar(
        title: const Text('AI Best Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: VolunteerColors.card,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hybrid Recommendation Engine',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _volunteerType == 'inexperienced' 
                    ? 'Since you are building your profile, we are suggesting easier, highly matching entry-level events to help you gain experience!'
                    : 'These suggestions are personalized based on your skills, history, and collaborative activity from similar active volunteers.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.robot, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No recommendations currently', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final manager = event['manager'] as Map<String, dynamic>?;
                          final companyName = manager?['company_name'] ?? manager?['full_name'] ?? 'Unknown Company';
                          
                          // Display rank
                          final matchRank = index + 1;

                          return Card(
                            color: VolunteerColors.card,
                            margin: const EdgeInsets.only(bottom: 24),
                            elevation: 4,
                            shadowColor: Colors.black12,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              onTap: () => _showEventDetails(event),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Rank badge and image
                                  Stack(
                                    children: [
                                      if (event['image_url'] != null && event['image_url'].toString().isNotEmpty)
                                        Image.network(
                                          event['image_url'],
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 120,
                                          width: double.infinity,
                                          color: Colors.grey[100],
                                          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                                        ),
                                        
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Top Match #$matchRank',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['name'] ?? 'No Title',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    companyName,
                                                    style: TextStyle(
                                                      color: VolunteerColors.accentSoftBlue,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_userApplications[event['id'].toString()] != null)
                                              _buildStatusBadge(_userApplications[event['id'].toString()]!),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(event['date'] ?? ''),
                                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                event['location'] ?? 'Online / Remote',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        Text(
                                          event['role_description'] ?? event['description'] ?? 'Join us for this exciting opportunity!',
                                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        _buildApplyButton(event),
                                      ],
                                    ),
                                  ),
                                ],
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

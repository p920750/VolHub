import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'volunteer_colors.dart';
import 'volunteer_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/event_manager_service.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _applicationsSubscription;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? userProfileImage;
  Map<String, String> _userApplications = {}; // eventId -> status

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;

    userProfileImage = (user?.userMetadata?['avatar_url'] as String?) ??
                       (user?.userMetadata?['picture'] as String?);
    
    _subscribeToEvents();
    _subscribeToApplications();
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

  void _subscribeToEvents() {
    setState(() => _isLoading = true);
    
    _eventsSubscription = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('date', ascending: true)
        .listen((List<Map<String, dynamic>> data) async {
          // Filter out filled events on the client side since stream filters don't support complex logic easily
          final openEvents = data.where((event) {
            final needed = (event['volunteers_needed'] as int?) ?? 0;
            final current = (event['current_volunteers_count'] as int?) ?? 0;
            return current < needed;
          }).toList();
          
          final enrichedEvents = await _enrichEventsWithManager(openEvents);
          
          if (mounted) {
            setState(() {
              _events = enrichedEvents;
              _applySorting(); // Maintain selected sort order
              _isLoading = false;
            });
          }
        }, onError: (error) {
          debugPrint('Stream Error: $error');
          if (mounted) setState(() => _isLoading = false);
        });
  }

  void _subscribeToApplications() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _applicationsSubscription = EventManagerService.getVolunteerApplicationsStream(user.id)
        .listen((List<Map<String, dynamic>> data) {
      debugPrint('Applications Stream Data received: ${data.length} items');
      for (var app in data) {
        debugPrint('Event ID: ${app['event_id']}, Status: ${app['status']}');
      }
      if (mounted) {
        setState(() {
          _userApplications = {
            for (var app in data) 
              app['event_id'].toString(): app['status'].toString()
          };
        });
      }
    }, onError: (error) {
      debugPrint('Applications Stream Error: $error');
    });
  }

  Future<List<Map<String, dynamic>>> _enrichEventsWithManager(List<Map<String, dynamic>> eventList) async {
    try {
      // Get all unique manager IDs
      final managerIds = eventList.map((e) => e['user_id'] ?? e['manager_id']).toSet().toList();
      if (managerIds.isEmpty) return eventList;

      // Fetch managers
      final managersResponse = await Supabase.instance.client
          .from('users')
          .select('id, full_name, company_name, company_location, profile_photo')
          .inFilter('id', managerIds);

      final managerMap = {for (var m in managersResponse) m['id']: m};

      // Merge data
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

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _removeOverlay();
    super.dispose();
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
      // _fetchEvents(); // No longer needed with real-time stream
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
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
        }
      } catch (e) {
        debugPrint('Error backing out: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  int _currentIndex = 0;
  String _selectedSortLabel = 'Sort by';
  final GlobalKey _sortKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isSortOpen = false;
  String? _expandedCategory;

  final Map<String, List<String>> sortOptions = {
    'Date Posted': ['Newest First', 'Oldest First'],
    'Event Date': ['Soonest First', 'Latest First'],
  };

  void _toggleSortDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    setState(() {
      _isSortOpen = true;
    });

    final renderBox = _sortKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    const double dropdownWidth = 320;

    double left = offset.dx;
    if (left + dropdownWidth > screenSize.width - 8) {
      left = screenSize.width - dropdownWidth - 8;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: offset.dy + renderBox.size.height + 6,
        width: dropdownWidth,
        child: Material(
          child: Container(
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
            decoration: BoxDecoration(
              color: VolunteerColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: sortOptions.entries.map((entry) {
                  final bool isExpanded = _expandedCategory == entry.key;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedCategory = isExpanded ? null : entry.key;
                          });
                          _overlayEntry?.markNeedsBuild();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Column(
                          children: entry.value.map((option) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSortLabel = option;
                                  _applySorting();
                                });
                                _removeOverlay();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                child: Align(alignment: Alignment.centerLeft, child: Text(option)),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _applySorting() {
    setState(() {
      switch (_selectedSortLabel) {
        case 'Newest First':
          _events.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
          break;
        case 'Oldest First':
          _events.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));
          break;
        case 'Soonest First':
          _events.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
          break;
        case 'Latest First':
          _events.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          break;
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _expandedCategory = null;
    if (mounted) {
      setState(() {
        _isSortOpen = false;
      });
    }
  }
  
  Color _getSlotsColor(int available, int total) {
    if (total <= 0) return Colors.red;
    final ratio = available / total;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.2) return Colors.orange;
    return Colors.red;
  }


  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'TBD';
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  String _formatCreatedDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute:$second';
    } catch (e) {
      return isoString;
    }
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final manager = event['manager'] as Map<String, dynamic>?;
    final companyName = manager?['company_name'] ?? manager?['full_name'] ?? 'Unknown Company';
    final categories = (event['categories'] as List?)?.join(', ') ?? 'No categories';
    
    final roleDescription = event['role_description'] ?? 'No role description provided.';
    final paymentType = event['payment_type'] ?? 'Unpaid';
    final paymentAmount = event['payment_amount'] ?? '';
    final isPaid = paymentType == 'Paid';
    final certificateProvided = event['certificate_provided'] == true;
    final foodProvided = event['food_provided'] == true;
    final skillsRequired = (event['skills_required'] as List?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              if (event['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(event['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 24),
              Text(event['name'] ?? 'No Title', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(companyName, style: TextStyle(color: VolunteerColors.accentSoftBlue, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.calendar_today, 'Date', _formatDate(event['date'] ?? '')),
              _buildDetailRow(Icons.location_on, 'Location', event['location'] ?? 'Remote'),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20, color: Colors.grey[600]),
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
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VolunteerColors.background,
      appBar: AppBar(
        backgroundColor: VolunteerColors.card,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: Image.asset(
              'assets/icons/icon_1.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VolunteerProfilePage()),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: VolunteerColors.accentSoftBlue,
                backgroundImage: userProfileImage != null ? NetworkImage(userProfileImage!) : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(FontAwesomeIcons.filter, size: 14),
                  label: const Text('Filter'),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  key: _sortKey,
                  onTap: _toggleSortDropdown,
                  child: Row(
                    children: [
                      Text(_selectedSortLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _isSortOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.boxOpen, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No events yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final manager = event['manager'] as Map<String, dynamic>?;
                          final companyName = manager?['company_name'] ?? manager?['full_name'] ?? 'Unknown Company';
                          final companyLocation = manager?['company_location'] ?? 'Location unknown';
                          final categories = (event['categories'] as List?)?.join(', ') ?? 'No categories';

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
                                  // Amazon style full-width image
                                  if (event['image_url'] != null && event['image_url'].toString().isNotEmpty)
                                    Stack(
                                      children: [
                                        Image.network(
                                          event['image_url'],
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.95),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getSlotsColor(
                                                  (event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0), 
                                                  event['volunteers_needed'] ?? 1
                                                ).withOpacity(0.5),
                                              ),
                                            ),
                                            child: Text(
                                              '${(event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0)} slots left',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getSlotsColor(
                                                  (event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0), 
                                                  event['volunteers_needed'] ?? 1
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
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
                                        
                                        // Key Details Grid-like layout
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
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.people_outline, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Available Slots: ${(event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0)}',
                                              style: TextStyle(
                                                color: _getSlotsColor(
                                                  (event['volunteers_needed'] ?? 0) - (event['current_volunteers_count'] ?? 0), 
                                                  event['volunteers_needed'] ?? 1
                                                ), 
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              event['payment_type'] == 'Paid' ? Icons.payment : Icons.volunteer_activism, 
                                              size: 18, 
                                              color: event['payment_type'] == 'Paid' ? Colors.green : Colors.grey
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              event['payment_type'] == 'Paid' 
                                                  ? 'Paid (${event['payment_amount'] ?? ''})' 
                                                  : 'Unpaid',
                                              style: TextStyle(
                                                color: event['payment_type'] == 'Paid' ? Colors.green[700] : Colors.grey[700], 
                                                fontSize: 13,
                                                fontWeight: event['payment_type'] == 'Paid' ? FontWeight.w600 : FontWeight.normal
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        if (event['categories'] != null && (event['categories'] as List).isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: (event['categories'] as List).map((cat) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                cat.toString(),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            )).toList(),
                                          ),
                                        ],

                                        const SizedBox(height: 20),
                                        Text(
                                          event['role_description'] ?? event['description'] ?? 'Join us for this exciting opportunity!',
                                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time_filled, size: 14, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Posted on: ${_formatCreatedDate(event['created_at'])}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.blue),
                                              ),
                                            ],
                                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.bars), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.comments), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.chartSimple), label: 'Board'),
        ],
      ),
    );
  }

  Widget _buildApplyButton(Map<String, dynamic> event) {
    final String eventId = event['id'].toString();
    final String? status = _userApplications[eventId];
    
    String buttonText = 'Apply Now';
    Color buttonColor = Colors.blueAccent;
    bool isEnabled = true;

    if (status != null) {
      isEnabled = status == 'accepted'; // Allow clicking if accepted to back out
      switch (status) {
        case 'accepted':
          buttonText = 'Back Out';
          buttonColor = Colors.red;
          break;
        case 'rejected':
          buttonText = 'Rejected';
          buttonColor = Colors.red;
          isEnabled = false;
          break;
        case 'withdrawn':
          buttonText = 'Withdrawn';
          buttonColor = Colors.grey;
          isEnabled = false;
          break;
        case 'pending':
        default:
          buttonText = 'Pending';
          buttonColor = Colors.orange;
          isEnabled = false;
          break;
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
          disabledForegroundColor: Colors.white.withOpacity(0.9),
        ),
        onPressed: isEnabled 
          ? (status == 'accepted' ? () => _handleBackOut(event) : () => _registerForEvent(event)) 
          : null,
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'volunteer_colors.dart';
import 'volunteer_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  StreamSubscription? _eventsSubscription;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;

    userProfileImage = (user?.userMetadata?['avatar_url'] as String?) ??
                       (user?.userMetadata?['picture'] as String?);
    
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    setState(() => _isLoading = true);
    
    // Use Supabase stream for real-time updates
    _eventsSubscription = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('date', ascending: true)
        .listen((List<Map<String, dynamic>> data) async {
          // Fetch manager details for each event (streams don't support joins directly in the same way)
          // For efficiency in a real app, you might want to cache manager data or use a view
          final enrichedEvents = await _enrichEventsWithManager(data);
          
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
      await Supabase.instance.client.from('event_applications').insert({
        'event_id': event['id'],
        'manager_id': event['user_id'] ?? event['manager_id'],
        'volunteer_id': user.id,
        'status': 'pending',
      });

      final currentCount = (event['current_volunteers_count'] ?? 0) as int;
      await Supabase.instance.client
          .from('events')
          .update({'current_volunteers_count': currentCount + 1})
          .eq('id', event['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully!')));
      // _fetchEvents(); // No longer needed with real-time stream
    } catch (e) {
      debugPrint('Error registering for event: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
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
                              onTap: () {
                                // Potentially navigate to event details page in future
                              },
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
                                              color: Colors.white.withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${event['current_volunteers_count'] ?? 0} applied',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent,
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
                                              'Volunteers needed: ${event['volunteers_needed'] ?? 0}',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
                                          event['description'] ?? 'Join us for this exciting opportunity!',
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
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: () => _registerForEvent(event),
                                            child: const Text(
                                              'Apply Now',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
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
}

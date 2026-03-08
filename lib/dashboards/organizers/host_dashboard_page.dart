import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import 'post_event_page.dart';
import 'host_messages_page.dart';
import 'my_events_page.dart';
import 'host_profile_page.dart';
import 'event_detail_page.dart';
import '../../services/host_service.dart';
import 'host_profile_provider.dart';

class HostDashboardPage extends ConsumerStatefulWidget {
  const HostDashboardPage({super.key});

  @override
  ConsumerState<HostDashboardPage> createState() => _HostDashboardPageState();
}

class _HostDashboardPageState extends ConsumerState<HostDashboardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadEvents();
    if (mounted) setState(() => _isLoading = false);
  }


  Future<void> _loadEvents() async {
    try {
      final events = await HostService.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(hostProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/organizer-profile');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 16,
                  child: _buildProfileImage(profile: profile, radius: 16),
                ),
                loading: () => const CircleAvatar(radius: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (err, stack) => const CircleAvatar(radius: 16, child: Icon(Icons.error)),
              ),
            ),
          ),
        ],
      ),
      drawer: profileAsync.when(
        data: (profile) => _buildDrawer(profile),
        loading: () => const Drawer(child: Center(child: CircularProgressIndicator())),
        error: (err, stack) => const Drawer(child: Center(child: Text('Error loading profile'))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.when(
                    data: (profile) => Text(
                      'Welcome back, ${profile.name.split(' ')[0]}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    loading: () => const Text('Welcome back! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    error: (err, stack) => const Text('Welcome back! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's what's happening with your requests today.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stat Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Active Requests', _events.where((e) => e['status']?.toString().toLowerCase() == 'active').length.toString(), Icons.calendar_today, Colors.green),
                      _buildStatCard('Pending Applications', '48', Icons.people_outline, Colors.blue),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/organizer-messages');
                        },
                        child: _buildStatCard('New Messages', '5', Icons.mail_outline, Colors.orange),
                      ),
                      _buildStatCard('Monthly Reach', '+24%', Icons.trending_up, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Engagement Overview Chart
                  const Text(
                    'Engagement Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 2),
                              FlSpot(2, 5),
                              FlSpot(3, 3),
                              FlSpot(4, 4),
                              FlSpot(5, 6),
                            ],
                            isCurved: true,
                            color: const Color(0xFF1E4D40),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF1E4D40).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Featured Events
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/my-events').then((_) => _loadData());
                        },
                        child: const Text('View All', style: TextStyle(color: Color(0xFF1E4D40))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _events.isEmpty 
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No requests found.'),
                      ))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _events.length > 3 ? 3 : _events.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _buildEventCard(event);
                        },
                      ),
                  const SizedBox(height: 12),
                  // Add a "Post a new event" button/card
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/post-event');
                      if (result == true) {
                        _loadData();
                      }
                    },
                    child: _buildPostEventCard(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDrawer(HostProfile? profile) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E4D40),
            ),
            child: profile != null ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: _buildProfileImage(profile: profile, radius: 30, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'HOST ACCOUNT',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ) : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', true),
          _buildDrawerItem(Icons.add_box_outlined, 'Post Request', false, onTap: () async {
            Navigator.pop(context);
            final result = await Navigator.pushNamed(context, '/post-event');
            if (result == true) {
              setState(() {});
            }
          }),
          _buildDrawerItem(Icons.mail_outline, 'Messages', false, onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/organizer-messages');
          }),
          _buildDrawerItem(Icons.event_note_outlined, 'My Requests', false, onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/my-events');
          }),
          const Divider(),
          _buildDrawerItem(Icons.logout, 'Logout', false, onTap: () {
            SupabaseService.signOut();
            ref.invalidate(hostProfileProvider);
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF1E4D40) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E4D40) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap ?? () {
        Navigator.pop(context);
      },
      selected: isSelected,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String title = event['title'] ?? 'Untitled Event';
    final String date = event['date'] ?? 'TBD';
    final String location = event['location'] ?? 'No location';
    final String stats = event['stats'] ?? 'No stats';
    final String status = event['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001529)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status.toLowerCase() == 'active' ? Colors.green[700] : Colors.orange[700],
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(date, style: const TextStyle(fontSize: 13, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(location, style: const TextStyle(fontSize: 13, color: Colors.grey))),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stats,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: event),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View Details', 
                        style: TextStyle(
                          fontSize: 13, 
                          color: Color(0xFF1E4D40), 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF1E4D40)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 120,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      if (kIsWeb) {
        return Image.network(
          url,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 120,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      }
      return Image.file(
        File(url),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 120,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildProfileImage({required HostProfile profile, required double radius, Color? color}) {
    return ClipOval(
      child: profile.profilePhoto.isNotEmpty ? Image.network(
        profile.profilePhoto,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.account_circle,
            size: radius * 2,
            color: color ?? Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ) : Icon(
          Icons.account_circle,
          size: radius * 2,
          color: color ?? Colors.grey,
        ),
    );
  }

  Widget _buildPostEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, color: Color(0xFF1E4D40)),
          ),
          const SizedBox(height: 12),
          const Text('Post a new request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import 'post_event_page.dart';
import 'host_messages_page.dart';
import 'my_events_page.dart';
import 'host_profile_page.dart';
import '../../services/host_service.dart';

class HostDashboardPage extends StatefulWidget {
  const HostDashboardPage({super.key});

  @override
  State<HostDashboardPage> createState() => _HostDashboardPageState();
}

class _HostDashboardPageState extends State<HostDashboardPage> {
  String _fullName = 'Alex Rivera';
  String _profilePhoto = 'https://i.pravatar.cc/150?u=alex';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userData = await SupabaseService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _fullName = userData['full_name'] ?? _fullName;
          _profilePhoto = userData['profile_photo'] ?? _profilePhoto;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Image.asset(
          'assets/images/logo_1.jpeg',
          height: 32,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HostProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_profilePhoto),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_fullName.split(' ')[0]}! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's happening with your events today.",
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
                    _buildStatCard('Active Events', '12', Icons.calendar_today, Colors.green),
                    _buildStatCard('Pending Applications', '48', Icons.people_outline, Colors.blue),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HostMessagesPage()),
                        );
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
                      'Featured Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All', style: TextStyle(color: Color(0xFF1E4D40))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: HostService.events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = HostService.events[index];
                    return _buildEventCard(
                      event['title'],
                      event['date'],
                      event['location'],
                      event['stats'],
                      event['status'],
                      event['imageUrl'],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Add a "Post a new event" button/card
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PostEventPage()),
                    );
                    if (result == true) {
                      _loadProfile(); // Refresh profile if needed, though mostly for events
                      setState(() {});
                    }
                  },
                  child: _buildPostEventCard(),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E4D40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(_profilePhoto),
                ),
                const SizedBox(height: 10),
                Text(
                  _fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'HOST ACCOUNT',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', true),
          _buildDrawerItem(Icons.add_box_outlined, 'Post Event', false, onTap: () async {
            Navigator.pop(context);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostEventPage()),
            );
            if (result == true) {
              setState(() {});
            }
          }),
          _buildDrawerItem(Icons.mail_outline, 'Messages', false, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HostMessagesPage()),
            );
          }),
          _buildDrawerItem(Icons.event_note_outlined, 'My Events', false, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyEventsPage()),
            );
          }),
          const Divider(),
          _buildDrawerItem(Icons.logout, 'Logout', false, onTap: () async {
            await SupabaseService.signOut();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
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

  Widget _buildEventCard(String title, String date, String location, String stats, String status, String imageUrl) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Active' ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stats, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Text('View Details', style: TextStyle(fontSize: 12, color: Color(0xFF1E4D40), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          const Text('Post a new event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

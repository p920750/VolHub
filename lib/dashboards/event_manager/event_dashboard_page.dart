import 'package:flutter/material.dart';
import 'event_colors.dart';

import '../../services/event_manager_service.dart';
import 'my_teams_page.dart';

import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'portfolio_page.dart';
import 'profile_page.dart';
import 'widgets/event_drawer.dart';

class EventDashboardPage extends StatefulWidget {
  const EventDashboardPage({super.key});

  @override
  State<EventDashboardPage> createState() => _EventDashboardPageState();
}


class _EventDashboardPageState extends State<EventDashboardPage> {
  late Future<Map<String, String>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _teamsFuture;
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  late Future<List<Map<String, dynamic>>> _proposalsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = EventManagerService.getDashboardStats();
      _teamsFuture = EventManagerService.getTeams();
      _applicationsFuture = EventManagerService.getRecentApplications();
      _proposalsFuture = EventManagerService.getRecentProposals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide back button
        backgroundColor: EventColors.headerBackground,
        title: const Text(
          'Volunteer Manager Platform',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Navigation Items
          _buildNavItem(context, 'Dashboard', isSelected: true),
          _buildNavItem(context, 'My Teams', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyTeamsPage()),
            );
          }),
          _buildNavItem(context, 'Recruit', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecruitPage()),
            );
          }),
          _buildNavItem(context, 'Event Marketplace', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventMarketplacePage()),
            );
          }),
          _buildNavItem(context, 'Proposals', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProposalsPage()),
            );
          }),
          _buildNavItem(context, 'Messages', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesPage()),
            );
          }),
          _buildNavItem(context, 'Portfolio', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PortfolioPage()),
            );
          }),
          _buildNavItem(context, 'Profile', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await Future.wait([_statsFuture, _teamsFuture, _applicationsFuture, _proposalsFuture]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Overview Header
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E4D40),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your volunteer teams, recruit new members, and track event proposals',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              FutureBuilder<Map<String, String>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final stats = snapshot.data ?? {};
                  
                  // Map the keys from service to the icon/structure needed by UI
                  final List<Map<String, dynamic>> statCards = [
                    {'title': 'Active Teams', 'value': stats['Active Teams'] ?? '0', 'icon': Icons.people_outline},
                    {'title': 'Total Members', 'value': stats['Total Members'] ?? '0', 'icon': Icons.group_outlined},
                    {'title': 'Open Job Postings', 'value': stats['Open Job Postings'] ?? '0', 'icon': Icons.work_outline},
                    {'title': 'Pending Applications', 'value': stats['Pending Applications'] ?? '0', 'icon': Icons.send_outlined},
                    {'title': 'Accepted Proposals', 'value': stats['Accepted Proposals'] ?? '0', 'icon': Icons.attach_money_outlined},
                    {'title': 'Pending Proposals', 'value': stats['Pending Proposals'] ?? '0', 'icon': Icons.trending_up},
                  ];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 3;
                      if (constraints.maxWidth < 800) crossAxisCount = 2;
                      if (constraints.maxWidth < 500) crossAxisCount = 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: statCards.length,
                        itemBuilder: (context, index) {
                          return _buildStatCard(statCards[index]);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // Your Teams Section
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _teamsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final teams = snapshot.data ?? [];
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: EventColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Teams',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (teams.isEmpty)
                          const Text("No active teams found.", style: TextStyle(color: Colors.white70)),
                        ...teams.map((team) => _buildTeamCard(team)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Recent Applications & Proposals Section
              LayoutBuilder(
                builder: (context, constraints) {
                  return FutureBuilder(
                    future: Future.wait([_applicationsFuture, _proposalsFuture]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      final applications = snapshot.data?[0] as List<Map<String, dynamic>>? ?? [];
                      final proposals = snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];

                      // Helper to convert dynamic map to string map for UI helper
                      List<Map<String, String>> convert(List<Map<String, dynamic>> list) {
                        return list.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList();
                      }

                      if (constraints.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRecentSection('Recent Applications', convert(applications)),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildRecentSection('Recent Proposals', convert(proposals)),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildRecentSection('Recent Applications', convert(applications)),
                            const SizedBox(height: 24),
                            _buildRecentSection('Recent Proposals', convert(proposals)),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, {bool isSelected = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: onTap ?? () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: EventColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  stat['title'],
                   style: const TextStyle(color: Colors.white70, fontSize: 13),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(stat['icon'], color: Colors.white70, size: 24),
            ],
          ),
          Text(
            stat['value'],
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.5), // Slightly lighter/different for contrast
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team['name'] ?? 'Unknown Team',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                team['role'] ?? 'No role',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              _buildTeamStat('Members', team['members']?.toString() ?? '0'),
              const SizedBox(width: 16),
              _buildTeamStat('Events', team['events']?.toString() ?? '0'),
              const SizedBox(width: 16),
              _buildTeamStat('Rating', '${team['rating'] ?? '0'} ★'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildRecentSection(String title, List<Map<String, String>> items) {
    return Container(
      decoration: BoxDecoration(
        color: EventColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
             const Text("No items found.", style: TextStyle(color: Colors.white70)),
          ...items.map((item) {
            bool isAccepted = item['status'] == 'accepted';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['role'] ?? item['price'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAccepted ? Colors.transparent : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: isAccepted ? Border.all(color: Colors.white54) : null,
                    ),
                    child: Text(
                      item['status'] ?? 'pending',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

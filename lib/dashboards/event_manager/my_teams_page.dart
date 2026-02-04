import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'portfolio_page.dart';
import 'profile_page.dart';

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({super.key});

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  // Mock Data for UI Development (will connect to service later)
  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'Professional Photography Team',
      'role': 'Photography',
      'description': 'Experienced photographers specializing in event coverage and portraits',
      'members_count': '2',
      'events_count': '12',
      'rating': '4.8',
      'skills': ['Photography', 'Editing', 'DSLR'],
      'members': [
        {
          'name': 'Alex Thompson',
          'role': 'Event Photography, Portrait, Editing',
          'hours': '45h',
          'initial': 'A',
          'color': Color(0xFF5C7C8A), // Muted Blue-Grey
        },
        {
          'name': 'Sarah Lee',
          'role': 'Wedding Photography, Drone, Videography',
          'hours': '32h',
          'initial': 'S',
          'color': Color(0xFF6B8E6B), // Muted Green
        },
      ],
    },
    {
      'name': 'Gourmet Catering Crew',
      'role': 'Catering',
      'description': 'Professional catering service for all types of events',
      'members_count': '1',
      'events_count': '18',
      'rating': '4.9',
      'skills': ['Catering', 'Food Safety'],
      'members': [
        {
          'name': 'Michael Chen',
          'role': 'Chef, Menu Planning, Food Safety',
          'hours': '78h',
          'initial': 'M',
          'color': Color(0xFF8A6B5C), // Muted Brown
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: EventColors.headerBackground,
        title: const Text(
          'Volunteer Manager Platform',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Teams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create and manage your volunteer teams',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ..._teams.map((team) => _buildDetailedTeamCard(team)),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailedTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3B2F), // Dark Green Background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Role, Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team['role'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              team['description'],
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildStatItem(Icons.people_outline, 'Members', team['members_count']),
                  const SizedBox(width: 24),
                  _buildStatItem(Icons.calendar_today_outlined, 'Events', team['events_count']),
                  const SizedBox(width: 24),
                  _buildStatItem(Icons.star_border, 'Rating', team['rating'], isRating: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Skill Groups
            Row(
              children: [
                const Icon(Icons.business_center_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Skill Groups',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  height: 6,
                  width: 100,
                   decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  // Progress bar placeholder if needed, matching image somewhat
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (team['skills'] as List<String>).map((skill) => _buildSkillTag(skill)).toList(),
            ),
            const SizedBox(height: 24),

            // Team Members Header
            const Text(
              'Team Members',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Member List
            ...(team['members'] as List<Map<String, dynamic>>).map((member) => _buildMemberRow(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {bool isRating = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Row(
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                if (isRating) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                ]
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member['color'],
            child: Text(member['initial'], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  member['role'],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Hours Contributed',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                member['hours'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

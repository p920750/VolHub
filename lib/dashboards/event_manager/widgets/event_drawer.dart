import 'package:flutter/material.dart';
import '../event_dashboard_page.dart';
import '../my_teams_page.dart';
import '../recruit_page.dart';
import '../event_marketplace_page.dart';
import '../proposals_page.dart';
import '../messages_page.dart';
import '../portfolio_page.dart';
import '../profile_page.dart';
import '../event_colors.dart';

class EventDrawer extends StatelessWidget {
  final String currentRoute;

  const EventDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: EventColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: EventColors.headerBackground,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 32,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volunteer Platform',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildDrawerItem(context, 'Dashboard', Icons.dashboard_outlined, const EventDashboardPage()),
                _buildDrawerItem(context, 'My Teams', Icons.people_outline, const MyTeamsPage()),
                _buildDrawerItem(context, 'Recruit', Icons.person_add_outlined, const RecruitPage()),
                _buildDrawerItem(context, 'Event Marketplace', Icons.store_outlined, const EventMarketplacePage()),
                _buildDrawerItem(context, 'Proposals', Icons.description_outlined, const ProposalsPage()),
                _buildDrawerItem(context, 'Messages', Icons.chat_bubble_outline, const MessagesPage()),
                _buildDrawerItem(context, 'Portfolio', Icons.work_outline, const PortfolioPage()),
                _buildDrawerItem(context, 'Profile', Icons.person_outline, const ProfilePage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget page) {
    final bool isSelected = currentRoute == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E4D40).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1E4D40) : Colors.black54,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E4D40) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'widgets/event_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock Data
  final Map<String, dynamic> _userProfile = {
    'first_name': 'John',
    'last_name': 'Manager',
    'email': 'john.manager@example.com',
    'phone': '(555) 123-4567',
    'location': 'San Francisco, CA',
    'organization': 'Volunteer Excellence Inc.',
    'role': 'Event Manager',
    'bio': 'Experienced volunteer manager with a passion for community service and event management.',
    'experience': '8 years',
    'expertise': ['Event Management', 'Team Leadership', 'Photography', 'Catering'],
    'certifications': ['Certified Event Manager', 'Project Management Professional'],
    'linkedin': 'https://linkedin.com/in/johnmanager',
    'website': 'https://volunteerexcellence.com',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventColors.background,
      drawer: const EventDrawer(currentRoute: 'Profile'),
      appBar: AppBar(
        // automaticallyImplyLeading: true,
        backgroundColor: EventColors.headerBackground,
        iconTheme: const IconThemeData(color: Colors.white),
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
              'My Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your personal information and professional details',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3B2F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF5C7C8A),
                        child: Text('JM', style: TextStyle(fontSize: 32, color: Colors.white)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${_userProfile['first_name']} ${_userProfile['last_name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userProfile['organization'],
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24),
                      _buildSidebarItem(Icons.email_outlined, _userProfile['email']),
                      const SizedBox(height: 16),
                      _buildSidebarItem(Icons.phone_outlined, _userProfile['phone']),
                      const SizedBox(height: 16),
                      _buildSidebarItem(Icons.location_on_outlined, _userProfile['location']),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // Right Content
                Expanded(
                  child: Column(
                    children: [
                      // Personal Information
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3B2F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, color: Colors.white70),
                                SizedBox(width: 12),
                                Text('Personal Information', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildInfoField('First Name', _userProfile['first_name'])),
                                const SizedBox(width: 24),
                                Expanded(child: _buildInfoField('Last Name', _userProfile['last_name'])),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildInfoField('Email', _userProfile['email'])),
                                const SizedBox(width: 24),
                                Expanded(child: _buildInfoField('Phone', _userProfile['phone'])),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildInfoField('Organization', _userProfile['organization'])),
                                const SizedBox(width: 24),
                                Expanded(child: _buildInfoField('Location', _userProfile['location'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Professional Information
                       Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3B2F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.business_center_outlined, color: Colors.white70),
                                SizedBox(width: 12),
                                Text('Professional Information', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoField('Biography', _userProfile['bio']),
                            const SizedBox(height: 24),
                            _buildInfoField('Years of Experience', _userProfile['experience']),
                            const SizedBox(height: 24),
                            const Text('Areas of Expertise', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_userProfile['expertise'] as List<String>).map((e) => _buildChip(e)).toList(),
                            ),
                          ],
                        ),
                      ),
                       const SizedBox(height: 24),

                      // Certifications & Links
                       Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3B2F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_outlined, color: Colors.white70),
                                SizedBox(width: 12),
                                Text('Certifications & Links', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('Certifications', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_userProfile['certifications'] as List<String>).map((e) => _buildChip(e)).toList(),
                            ),
                            const SizedBox(height: 24),
                            _buildLinkField('LinkedIn Profile', _userProfile['linkedin']),
                            const SizedBox(height: 16),
                            _buildLinkField('Website', _userProfile['website']),
                          ],
                        ),
                      ),
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


  Widget _buildSidebarItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildLinkField(String label, String url) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.link, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(url, style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.underline)),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

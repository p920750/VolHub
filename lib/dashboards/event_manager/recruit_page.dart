import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'widgets/event_drawer.dart';

class RecruitPage extends StatefulWidget {
  const RecruitPage({super.key});

  @override
  State<RecruitPage> createState() => _RecruitPageState();
}

class _RecruitPageState extends State<RecruitPage> {
  // Mock Data
  final List<Map<String, dynamic>> _jobPostings = [
    {
      'title': 'Event Photographer Needed',
      'team': 'Professional Photography Team',
      'description': 'Looking for skilled photographers to join our team',
      'status': 'open',
      'required_skills': ['Event Photography', 'Editing', 'DSLR'],
      'applications': [
        {
          'name': 'Emma Wilson',
          'email': 'emma@email.com',
          'skills': 'Event Photography, Portrait, Adobe Lightroom',
          'experience': '3 years freelance photography',
          'applied_date': '2025-01-06',
          'initial': 'E',
          'color': const Color(0xFF5C7C8A),
        },
        {
          'name': 'James Rodriguez',
          'email': 'james@email.com',
          'skills': 'Wedding Photography, Editing, Canon',
          'experience': '5 years professional photography',
          'applied_date': '2025-01-07',
          'initial': 'J',
          'color': const Color(0xFF6B8E6B),
        },
      ],
    },
     {
      'title': 'Catering Assistant',
      'team': 'Gourmet Catering Crew',
      'description': 'Assist with food preparation and serving at large events.',
      'status': 'open',
      'required_skills': ['Food Safety', 'Serving', 'Hygiene'],
      'applications': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventColors.background,
      drawer: const EventDrawer(currentRoute: 'Recruit'),
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
              'Recruit Volunteers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Post job openings and review applications',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ..._jobPostings.map((job) => _buildJobCard(job)),
          ],
        ),
      ),
    );
  }


  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3B2F), // Dark Green
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['team'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        job['status'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                     Container(
                      width: 60,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      // Placeholder for action button (Edit/Menu)
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Description
            Text(
              job['description'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Required Skills
            const Text(
              'Required Skills:',
               style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (job['required_skills'] as List).cast<String>().map((skill) => _buildSkillTag(skill)).toList(),
            ),
            const SizedBox(height: 24),

            // Applications Header
            Text(
              'Applications (${(job['applications'] as List).length} pending)',
               style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Applications List
             ...(job['applications'] as List).cast<Map<String, dynamic>>().map((app) => _buildApplicationRow(app)),
          ],
        ),
      ),
    );
  }

   Widget _buildSkillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildApplicationRow(Map<String, dynamic> app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: app['color'],
            child: Text(app['initial'], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                 Text(
                  app['email'],
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skills: ${app['skills']}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Experience: ${app['experience']}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applied: ${app['applied_date']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               const SizedBox(height: 16), // Push buttons down to match design closer
               Row(
                 children: [
                   Container(
                     height: 32,
                     width: 48,
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     // Accept button placeholder
                   ),
                   const SizedBox(width: 8),
                   Container(
                     height: 32,
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: const Center(
                       child: Row(
                         children: [
                           Icon(Icons.close, color: Colors.redAccent, size: 16),
                           SizedBox(width: 4),
                           Text(
                             'Reject',
                             style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
            ],
          ),
        ],
      ),
    );
  }
}

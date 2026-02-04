import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  // Mock Data
  final Map<String, int> _stats = {
    'Total Events': 2,
    'Active Teams': 2,
    'Testimonials': 2,
  };

  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'Winter Charity Gala',
      'team': 'Gourmet Catering Crew',
      'date': 'December 5, 2024',
      'description': 'Catering and photography services for fundraising event',
      'testimonial': 'Professional service from start to finish. Highly recommended!',
      'testimonial_author': '- Event Host',
      'image_color': Colors.orangeAccent, // Placeholder color
      'has_certificates': false,
    },
    {
      'title': 'Annual Tech Summit 2024',
      'team': 'Professional Photography Team',
      'date': 'November 15, 2024',
      'description': 'Provided full photography coverage for 3-day technology conference',
      'testimonial': 'Exceptional work! The photos captured the energy of our event perfectly.',
      'testimonial_author': '- Event Host',
      'image_color': Colors.blueAccent, // Placeholder color
      'has_certificates': false,
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
              'Portfolio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Showcase your completed events and achievements',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Events', _stats['Total Events']!, Icons.bookmark_border)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Active Teams', _stats['Active Teams']!, Icons.people_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Testimonials', _stats['Testimonials']!, Icons.format_quote)),
              ],
            ),
            const SizedBox(height: 32),

            // Projects List
            ..._projects.map((project) => _buildProjectCard(project)),
          ],
        ),
      ),
    );
  }


  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3B2F),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Icon(icon, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3B2F),
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
                      project['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.white),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             project['team'],
                             style: const TextStyle(color: Colors.white, fontSize: 11),
                           ),
                         ),
                         const SizedBox(width: 12),
                         Icon(Icons.calendar_today, color: Colors.white54, size: 14),
                         const SizedBox(width: 4),
                         Text(
                          project['date'],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                       ],
                    ),
                  ],
                ),
                Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              project['description'],
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
             const SizedBox(height: 16),

             // Event Photos
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Row(
                   children: [
                     Icon(Icons.image_outlined, color: Colors.white, size: 16),
                     SizedBox(width: 8),
                     Text('Event Photos', style: TextStyle(color: Colors.white, fontSize: 14)),
                   ],
                 ),
                 Container(
                   width: 80,
                   height: 24,
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.9),
                     borderRadius: BorderRadius.circular(4),
                   ),
                   // Placeholder for "Add Photos" or similar
                 ),
               ],
             ),
             const SizedBox(height: 12),
             Container(
               height: 200,
               width: double.infinity,
               decoration: BoxDecoration(
                 color: project['image_color'],
                 borderRadius: BorderRadius.circular(8),
                   image: const DecorationImage(
                   image: NetworkImage('https://images.unsplash.com/photo-1561489413-985b06da5bee?auto=format&fit=crop&q=80&w=1000'), // Generic placeholder
                   fit: BoxFit.cover,
                 ),
               ),
               // If we want specific images as per design, we'd mock them better, 
               // but a generic placeholder works for "Event Photos" if we don't have assets.
               // The user image shows food for the first one and a person for the second.
               // I'll stick to a generic one or just a colored box if network fails, but let's try a network placeholder.
             ),
             const SizedBox(height: 24),

             // Testimonial
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF2C3E50).withOpacity(0.4),
                 borderRadius: BorderRadius.circular(8),
                 border: Border(left: BorderSide(color: Colors.white.withOpacity(0.5), width: 3)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(Icons.format_quote, color: Colors.white70, size: 20),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           '"${project['testimonial']}"',
                           style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13),
                         ),
                       ),
                     ],
                   ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                         project['testimonial_author'],
                         style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                 ],
               ),
             ),
             const SizedBox(height: 24),

             // Certificates
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Row(
                   children: [
                     Icon(Icons.description_outlined, color: Colors.white, size: 16),
                     SizedBox(width: 8),
                     Text('Certificates & Documents', style: TextStyle(color: Colors.white, fontSize: 14)),
                   ],
                 ),
                 Container(
                   width: 80,
                   height: 24,
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.9),
                     borderRadius: BorderRadius.circular(4),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             Container(
               height: 80,
               width: double.infinity,
               decoration: BoxDecoration(
                 color: const Color(0xFF2C3E50),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.white24),
               ),
               child: const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.description_outlined, color: Colors.white54, size: 24),
                     SizedBox(height: 4),
                     Text(
                       'No certificates uploaded yet',
                       style: TextStyle(color: Colors.white54, fontSize: 12),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}

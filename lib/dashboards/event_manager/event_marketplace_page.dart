import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'recruit_page.dart';
import 'proposals_page.dart';
import 'messages_page.dart';
import 'portfolio_page.dart';
import 'profile_page.dart';

class EventMarketplacePage extends StatefulWidget {
  const EventMarketplacePage({super.key});

  @override
  State<EventMarketplacePage> createState() => _EventMarketplacePageState();
}

class _EventMarketplacePageState extends State<EventMarketplacePage> {
  // Mock Data
  final List<String> _categories = ['All', 'Photography', 'Catering', 'Music', 'Security', 'Cleanup'];
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Conference Photography & Catering',
      'event_name': 'Tech Conference 2025',
      'description': 'Need professional photography and catering for 3-day tech conference with 500 attendees',
      'date': '2025-02-15',
      'location': 'San Francisco Convention Center',
      'budget': '\$5000',
      'requirements': ['Photography', 'Catering', 'Videography'],
      'posted_date': '2025-01-08',
      'status': 'open',
      'proposal_sent': true,
    },
    {
      'title': 'Wedding Photography Package',
      'event_name': 'Community Wedding',
      'description': 'Looking for wedding photographer for intimate ceremony',
      'date': '2025-03-22',
      'location': 'Garden Venue, Oakland',
      'budget': '\$2500',
      'requirements': ['Wedding Photography', 'Photo Editing'],
      'posted_date': '2025-01-07',
      'status': 'open',
      'proposal_sent': true,
    },
    {
      'title': 'Corporate Event Services',
      'event_name': 'Corporate Gala',
      'description': 'Need catering and photography for annual corporate gala',
      'date': '2025-02-28',
      'location': 'Hilton Hotel Ballroom',
      'budget': '\$4000',
      'requirements': ['Catering', 'Event Photography'],
      'posted_date': '2025-01-06',
      'status': 'open',
      'proposal_sent': false,
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
              'Event Marketplace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse event requests from hosts and send proposals',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                 color: const Color(0xFF1A3B2F),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.white24),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.white70),
                  hintText: 'Search events by title, description, host, or location...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                const Text('Filter by Category', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) => _buildCategoryChip(category)).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Event List
            ..._events.map((event) => _buildEventCard(event)),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E4D40) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
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
                      event['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                       children: [
                         const Icon(Icons.apartment, color: Colors.white54, size: 16),
                         const SizedBox(width: 4),
                         Text(
                          event['event_name'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                       ],
                    ),
                  ],
                ),
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    event['status'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              event['description'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Info Row (Date, Location, Budget)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              child: Row(
                children: [
                  _buildInfoItem(Icons.calendar_today, 'Date', event['date']),
                  const SizedBox(width: 32),
                  Expanded(child: _buildInfoItem(Icons.location_on, 'Location', event['location'])),
                  const SizedBox(width: 32),
                   _buildInfoItem(Icons.attach_money, 'Budget', event['budget']),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Requirements
             const Text(
              'Requirements:',
               style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (event['requirements'] as List<String>).map((req) => _buildRequirementTag(req)).toList(),
            ),
            const SizedBox(height: 24),

            // Footer (Posted Date + Action Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posted: ${event['posted_date']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Row(
                  children: [
                     Container(
                      width: 100,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                       // View details placeholder
                    ),
                    const SizedBox(width: 12),
                    if (event['proposal_sent'])
                      const Text('Proposal Sent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                    else 
                      Container(
                      width: 100,
                      height: 36,
                       decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                       // Send Proposal placeholder
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }

   Widget _buildRequirementTag(String label) {
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
}

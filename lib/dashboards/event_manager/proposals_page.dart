import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'messages_page.dart';
import 'portfolio_page.dart';
import 'profile_page.dart';

class ProposalsPage extends StatefulWidget {
  const ProposalsPage({super.key});

  @override
  State<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage> {
  // Mock Data
  final Map<String, int> _stats = {
    'Pending': 1,
    'Accepted': 1,
    'Rejected': 0,
  };

  final List<Map<String, dynamic>> _proposals = [
    {
      'title': 'Conference Photography & Catering',
      'event_name': 'Tech Conference 2025',
      'team': 'Professional Photography Team',
      'status': 'pending',
      'event_date': '2025-02-15',
      'host_budget': '\$5000',
      'your_proposal': '\$3500',
      'message': 'We would love to provide photography services for your conference. Our team has extensive experience with multi-day events.',
      'sent_date': '2025-01-08',
    },
     {
      'title': 'Wedding Photography Package',
      'event_name': 'Community Wedding',
      'team': 'Professional Photography Team',
      'status': 'accepted',
      'event_date': '2025-03-22',
      'host_budget': '\$2500',
      'your_proposal': '\$2500',
      'message': 'Our wedding photography package includes full-day coverage and professional editing.',
      'sent_date': '2025-01-08',
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
              'My Proposals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track all your event proposals and their status',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending', _stats['Pending']!, Icons.access_time)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Accepted', _stats['Accepted']!, Icons.check_circle_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Rejected', _stats['Rejected']!, Icons.cancel_outlined, isDestructive: true)),
              ],
            ),
            const SizedBox(height: 32),

            // Proposals List
            ..._proposals.map((proposal) => _buildProposalCard(proposal)),
          ],
        ),
      ),
    );
  }


  Widget _buildStatCard(String title, int count, IconData icon, {bool isDestructive = false}) {
    // Colors based on the image: Dark Green cards.
    // The rejected one in the image is still a dark card but with a red X icon.
    // The accepted one has a check icon.
    // Pending has a clock icon.
    
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
                style: TextStyle(
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    bool isPending = proposal['status'] == 'pending';
    bool isAccepted = proposal['status'] == 'accepted';
    
    Color statusColor = isAccepted ? Colors.greenAccent : (isPending ? Colors.white70 : Colors.redAccent);
    IconData statusIcon = isAccepted ? Icons.check_circle_outline : (isPending ? Icons.access_time : Icons.cancel_outlined);

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
                      proposal['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                       children: [
                         const Icon(Icons.apartment, color: Colors.white70, size: 16),
                         const SizedBox(width: 4),
                         Text(
                          proposal['event_name'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                       ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      proposal['team'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                       Icon(statusIcon, color: statusColor, size: 14),
                       const SizedBox(width: 6),
                       Text(
                        proposal['status'],
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and Amount Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2C3E50).withOpacity(0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Event Date', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(proposal['event_date'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                   Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Proposal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(proposal['your_proposal'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Your Message Box section
            const Text('Your Message:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2C3E50).withOpacity(0.4),
              ),
              child: Text(
                proposal['message'],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
             const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sent: ${proposal['sent_date']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  'Host Budget: ${proposal['host_budget']}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'widgets/event_request_card.dart';
import '../core/manager_drawer.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = [
      {
        'title': 'Corporate Charity Gala',
        'description': 'Need a full team of volunteers for registration, ushering, and general assistance during our annual charity gala.',
        'date': 'Oct 15, 2026',
        'location': 'Grand Hotel, NYC',
        'budget': '\$2,500',
        'posted_by': 'Global Corp Events'
      },
      {
        'title': 'Community Cleanup Drive',
        'description': 'Seeking enthusiastic volunteers to help coordinate our weekend cleanup drive. Safety gear providing.',
        'date': 'Sep 22, 2026',
        'location': 'Central Park',
        'budget': '\$500',
        'posted_by': 'Green Earth NGO'
      },
      {
        'title': 'Tech Conference 2026',
        'description': 'Looking for experienced event staff for registration and speaker assistance. 3-day event.',
        'date': 'Nov 05-07, 2026',
        'location': 'Convention Center',
        'budget': '\$5,000',
        'posted_by': 'TechWorld Inc.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-marketplace'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search skills, titles, or locations...',
              leading: const Icon(Icons.search),
              onChanged: (value) {},
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return EventRequestCard(
                  request: requests[index],
                  onSendProposal: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proposal sent! (Mock)')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

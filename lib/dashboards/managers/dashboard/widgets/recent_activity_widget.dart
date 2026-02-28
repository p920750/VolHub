import 'package:flutter/material.dart';
import 'matching_events_widget.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                width: 300,
                child: TabBar(
                  tabs: [
                    Tab(text: 'Matches'),
                    Tab(text: 'Apps'),
                    Tab(text: 'Proposals'),
                  ],
                  labelPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                const SingleChildScrollView(child: MatchingEventsWidget()),
                _buildApplicationsList(context),
                _buildProposalsList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(BuildContext context) {
    final apps = [
      {'name': 'John Doe', 'role': 'Photographer', 'status': 'Pending', 'date': '2h ago'},
      {'name': 'Jane Smith', 'role': 'Event Coordinator', 'status': 'Accepted', 'date': '5h ago'},
      {'name': 'Mike Ross', 'role': 'Logistics', 'status': 'Pending', 'date': '1d ago'},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return ListTile(
          leading: CircleAvatar(child: Text((app['name'] as String)[0])),
          title: Text(app['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${app['role']} • ${app['date']}'),
          trailing: Chip(
            label: Text(
              app['status'] as String, 
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: app['status'] == 'Accepted' 
                    ? Theme.of(context).colorScheme.onPrimaryContainer 
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            backgroundColor: (app['status'] == 'Accepted' 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : Theme.of(context).colorScheme.secondaryContainer),
            side: BorderSide.none,
          ),
        );
      },
    );
  }

  Widget _buildProposalsList(BuildContext context) {
    final props = [
      {'event': 'Tech Summit 2026', 'budget': '\$500', 'status': 'Accepted', 'date': '1d ago'},
      {'event': 'Music Fest', 'budget': '\$1200', 'status': 'Pending', 'date': '2d ago'},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: props.length,
      itemBuilder: (context, index) {
        final prop = props[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.confirmation_number, color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          title: Text(prop['event'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Budget: ${prop['budget']} • ${prop['date']}'),
          trailing: Chip(
            label: Text(
              prop['status'] as String, 
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: prop['status'] == 'Accepted' 
                    ? Theme.of(context).colorScheme.onPrimaryContainer 
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            backgroundColor: (prop['status'] == 'Accepted' 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : Theme.of(context).colorScheme.secondaryContainer),
            side: BorderSide.none,
          ),
        );
      },
    );
  }
}

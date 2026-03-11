import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'matching_events_widget.dart';
import '../recent_activity_providers.dart';
import '../../../../utils/date_formatter.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                _buildApplicationsList(context, ref),
                _buildProposalsList(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(recentApplicationsProvider);

    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return const Center(child: Text('No recent applications'));
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: app['avatarUrl'] != null ? NetworkImage(app['avatarUrl']) : null,
                child: app['avatarUrl'] == null ? Text((app['name'] as String)[0]) : null,
              ),
              title: Text(app['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${app['role']} • ${DateFormatter.timeAgo(app['date'])}'),
              trailing: Chip(
                label: Text(
                  app['status'] as String, 
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: app['status'].toString().toLowerCase() == 'accepted' 
                        ? Theme.of(context).colorScheme.onPrimaryContainer 
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor: (app['status'].toString().toLowerCase() == 'accepted' 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.secondaryContainer),
                side: BorderSide.none,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildProposalsList(BuildContext context, WidgetRef ref) {
    final propsAsync = ref.watch(recentProposalsProvider);

    return propsAsync.when(
      data: (props) {
        if (props.isEmpty) {
          return const Center(child: Text('No recent proposals'));
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
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
              subtitle: Text('Budget: ${prop['budget']} • ${DateFormatter.timeAgo(prop['date'])}'),
              trailing: Chip(
                label: Text(
                  prop['status'] as String, 
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: prop['status'].toString().toLowerCase() == 'accepted' 
                        ? Theme.of(context).colorScheme.onPrimaryContainer 
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor: (prop['status'].toString().toLowerCase() == 'accepted' 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.secondaryContainer),
                side: BorderSide.none,
              ),
              onTap: () {
                if (kDebugMode) print('Tapped activity proposal: ${prop['event']}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

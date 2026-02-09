import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/stats_grid.dart';
import 'widgets/dashboard_charts.dart';
import 'widgets/your_teams_widget.dart';
import '../profile/profile_provider.dart';
import '../core/manager_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/manager-profile'),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(profile.profileImage),
              ),
            ),
          ),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${profile.name.split(' ')[0]}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is what\'s happening today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const StatsGrid(),
            const SizedBox(height: 24),
            const DashboardCharts(),
            const SizedBox(height: 24),
            const YourTeamsWidget(),
            const SizedBox(height: 24),
            const RecentActivityWidget(),
          ],
        ),
      ),
    );
  }
}

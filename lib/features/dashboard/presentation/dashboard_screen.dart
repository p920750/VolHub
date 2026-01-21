import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vol_hub/features/dashboard/presentation/widgets/recent_activity_widget.dart';
import 'package:vol_hub/features/dashboard/presentation/widgets/stats_grid.dart';
import 'package:vol_hub/features/dashboard/presentation/widgets/dashboard_charts.dart';
import 'package:vol_hub/features/dashboard/presentation/widgets/your_teams_widget.dart';
import 'package:vol_hub/features/profile/data/profile_provider.dart';

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
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(profile.profileImage),
              ),
            ),
          ),
        ],
      ),
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

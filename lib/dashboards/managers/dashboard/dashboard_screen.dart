import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/stats_grid.dart';
import 'widgets/your_teams_widget.dart';
import '../profile/profile_provider.dart';
import '../core/manager_drawer.dart';
import '../../shared/notifications_screen.dart';
import '../../../services/notification_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: NotificationService.getNotificationsStream(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !(n['is_read'] ?? false)).length;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/manager-profile'),
              child: profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 16,
                  backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
                  child: profile.profileImage.isEmpty ? const Icon(Icons.person) : null,
                ),
                loading: () => const CircleAvatar(radius: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (err, stack) => const CircleAvatar(radius: 16, child: Icon(Icons.error)),
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
             profileAsync.when(
              data: (profile) => Text(
                'Welcome back, ${profile.name.split(' ')[0]}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              loading: () => Text( // Skeleton or placeholder
                'Welcome back...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              error: (err, stack) => const Text('Welcome'),
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
            const YourTeamsWidget(),
            const SizedBox(height: 24),
            const RecentActivityWidget(),
          ],
        ),
      ),
    );
  }
}

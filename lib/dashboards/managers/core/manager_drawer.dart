import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../profile/profile_provider.dart';
import '../../../services/supabase_service.dart';
import 'theme.dart';

class ManagerDrawer extends ConsumerWidget {
  final String currentRoute;

  const ManagerDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Drawer(
      backgroundColor: AppColors.midnightBlue,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E2A38),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profile.profileImage),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'MANAGER',
                        style: TextStyle(
                          color: AppColors.mintIce.withOpacity(0.8),
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/manager-dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.storefront_outlined,
                  label: 'Marketplace',
                  route: '/manager-marketplace',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.message_outlined,
                  label: 'Messages',
                  route: '/manager-messages',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.folder_shared_outlined,
                  label: 'Portfolio',
                  route: '/manager-portfolio',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Proposals',
                  route: '/manager-proposals',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_search_outlined,
                  label: 'Recruit',
                  route: '/manager-recruit',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  label: 'My Teams',
                  route: '/manager-teams',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  route: '/manager-profile',
                ),
                const Divider(color: Colors.white10),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  route: '/login',
                  onTap: () async {
                    await SupabaseService.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    VoidCallback? onTap,
  }) {
    final bool isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.mintIce : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.mintIce : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.05),
      onTap: onTap ?? () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'profile_provider.dart';
import '../core/manager_drawer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit), 
            onPressed: () => Navigator.pushNamed(context, '/manager-profile-edit'),
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-profile'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profile.profileImage),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              profile.role,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSection(
                    context,
                    'Overview',
                    [
                      _buildInfoRow(Icons.email, profile.email),
                      _buildInfoRow(Icons.phone, profile.phone),
                      _buildInfoRow(Icons.location_on, profile.location),
                    ],
                    onEdit: () => Navigator.pushNamed(context, '/manager-profile-edit'),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    'Professional Info',
                    [
                       Text(profile.bio),
                       const SizedBox(height: 12),
                       Wrap(
                         spacing: 8,
                         children: const [
                           Chip(label: Text('Event Planning')),
                           Chip(label: Text('Logistics')),
                           Chip(label: Text('Budgeting')),
                         ],
                       ),
                    ],
                    onEdit: () => Navigator.pushNamed(context, '/manager-profile-edit'),
                  ),
                   const SizedBox(height: 16),
                  _buildSection(
                    context,
                    'Certifications & Links',
                    [
                      ListTile(
                        leading: const Icon(FontAwesomeIcons.linkedin, color: Colors.blue),
                        title: const Text('LinkedIn Profile'),
                        subtitle: Text(
                          profile.linkedinUrl, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigating to ${profile.linkedinUrl}')),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => Navigator.pushNamed(context, '/manager-profile-edit'),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(FontAwesomeIcons.certificate, color: Colors.orange),
                        title: Text(profile.certName),
                        subtitle: Text(profile.certIssuedDate),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Certification details coming soon!')),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => Navigator.pushNamed(context, '/manager-profile-edit'),
                        ),
                      ),
                    ],
                    onEdit: () => Navigator.pushNamed(context, '/manager-profile-edit'),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

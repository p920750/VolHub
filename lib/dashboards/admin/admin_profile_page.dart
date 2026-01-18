import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_colors.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'admin@volhub.com';

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: const Text('Admin Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AdminColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AdminColors.accent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Administrator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            Text(
              email,
              style: const TextStyle(
                fontSize: 16,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileOption(
              context,
              'Sign Out',
              Icons.logout,
              Colors.red,
              () async {
                await SupabaseService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
      ),
    );
  }
}

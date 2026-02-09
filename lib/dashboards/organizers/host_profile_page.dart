import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class HostProfilePage extends StatefulWidget {
  const HostProfilePage({super.key});

  @override
  State<HostProfilePage> createState() => _HostProfilePageState();
}

class _HostProfilePageState extends State<HostProfilePage> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final fullName = userData?['full_name'] ?? 'Alex Rivera';
        final profilePhoto = userData?['profile_photo'] ?? 'https://i.pravatar.cc/150?u=alex';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(profilePhoto),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Event Host / Organizer',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      _buildProfileItem(Icons.person_outline, 'Edit Profile'),
                      _buildProfileItem(Icons.notifications_none, 'Notifications'),
                      _buildProfileItem(Icons.security, 'Security'),
                      _buildProfileItem(Icons.help_outline, 'Help & Support'),
                      const Divider(indent: 24, endIndent: 24),
                      _buildProfileItem(
                        Icons.logout,
                        'Logout',
                        textColor: Colors.red,
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
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {Color? textColor, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black87, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

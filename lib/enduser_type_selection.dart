import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'dashboards/volunteers/volunteer_home_page.dart';
import 'volunteer_type_selection.dart';

class EndUserTypeSelectionPage extends StatefulWidget {
  const EndUserTypeSelectionPage({super.key});

  @override
  State<EndUserTypeSelectionPage> createState() => _EndUserTypeSelectionPageState();
}

class _EndUserTypeSelectionPageState extends State<EndUserTypeSelectionPage> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('No user found');

      // Check if user already exists in public.users
      final existingUser = await SupabaseService.getUserFromUsersTable();

      if (existingUser == null) {
        // New user from Google/OAuth - insert record
        await SupabaseService.insertUserIntoUsersTable(
          id: user.id,
          role: role,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
          avatarUrl: user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
          isEmailVerified: true, // Google accounts are verified
        );
      } else {
        // Existing user record - update role
        await SupabaseService.updateUsersTable({
          'role': role,
          'is_email_verified': true,
        });
      }

      if (mounted) {
        if (role == 'volunteer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VolunteerTypeSelectionPage()),
          );
        } else if (role == 'organizer') {
          // Redirect to organizer dashboard (commented out per request)
          /*
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrganizerDashboardPage()),
          );
          */
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Organizer Dashboard coming soon!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light green
              Color(0xFFC8E6C9), // Muted green
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Register as",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32), // Dark success green
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 60), // More space from title
                    _RoleButton(
                      label: "Volunteers",
                      onPressed: () => _selectRole('volunteer'),
                      icon: Icons.people_outline,
                      color: const Color(0xFF43A047),
                    ),
                    const SizedBox(height: 40), // Equidistant spacing (almost)
                    _RoleButton(
                      label: "Event Organizers",
                      onPressed: () => _selectRole('organizer'),
                      icon: Icons.event_available_outlined,
                      color: const Color(0xFF1B5E20),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const _RoleButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

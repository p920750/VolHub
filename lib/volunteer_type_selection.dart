import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'dashboards/volunteers/volunteer_home_page.dart';

class VolunteerTypeSelectionPage extends StatefulWidget {
  const VolunteerTypeSelectionPage({super.key});

  @override
  State<VolunteerTypeSelectionPage> createState() => _VolunteerTypeSelectionPageState();
}

class _VolunteerTypeSelectionPageState extends State<VolunteerTypeSelectionPage> {
  bool _isLoading = false;

  Future<void> _selectVolunteerType(String type) async {
    setState(() => _isLoading = true);
    try {
      // Update public.users table with volunteer_type
      await SupabaseService.updateUsersTable({
        'volunteer_type': type,
      });

      if (mounted) {
        // Redirect to volunteer home page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/volunteer-dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating volunteer type: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
                      "What type of volunteer you are?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 60), // More space from title
                    _TypeButton(
                      label: "Experienced",
                      onPressed: () => _selectVolunteerType('experienced'),
                      icon: Icons.star_outline,
                      color: const Color(0xFF43A047),
                    ),
                    const SizedBox(height: 40), // Equidistant spacing
                    _TypeButton(
                      label: "Inexperienced",
                      onPressed: () => _selectVolunteerType('inexperienced'),
                      icon: Icons.school_outlined,
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

class _TypeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const _TypeButton({
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../widgets/safe_avatar.dart';

class VolunteerPublicProfilePage extends StatefulWidget {
  final String volunteerId;

  const VolunteerPublicProfilePage({super.key, required this.volunteerId});

  @override
  State<VolunteerPublicProfilePage> createState() => _VolunteerPublicProfilePageState();
}

class _VolunteerPublicProfilePageState extends State<VolunteerPublicProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getUserProfileById(widget.volunteerId);
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Not Found')),
        body: const Center(child: Text('Could not load volunteer profile.')),
      );
    }

    final String name = _profileData!['full_name'] ?? 'Volunteer';
    final String email = _profileData!['email'] ?? 'Not specified';
    final String phone = _profileData!['phone_number'] ?? 'Not specified';
    final String location = _profileData!['location'] ?? 'Location N/A';
    final String bio = _profileData!['bio'] ?? 'No bio provided.';
    final String? photoUrl = _profileData!['profile_photo'];

    final int expYears = _profileData!['experience_years'] ?? 0;
    
    // Safely parse lists
    List<String> skills = [];
    if (_profileData!['skills'] != null) {
      skills = List<String>.from(_profileData!['skills']);
    }

    List<String> languages = [];
    if (_profileData!['languages'] != null) {
      languages = List<String>.from(_profileData!['languages']);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$name\'s Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SafeAvatar(
                radius: 60,
                imageUrl: photoUrl,
                name: name,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('$expYears Years Experience', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Location', location),
            const Divider(height: 48),
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 13, color: Colors.white)),
                  backgroundColor: const Color(0xFF00AA8D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side:BorderSide.none),
                )).toList(),
              ),
            ],
            if (languages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Languages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages.map((l) => Chip(
                  label: Text(l, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side:BorderSide.none),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E4D40)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}

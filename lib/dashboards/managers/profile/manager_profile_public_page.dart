import 'package:flutter/material.dart';
import '../../../services/host_service.dart';
import '../../../../widgets/safe_avatar.dart';

class ManagerProfilePublicPage extends StatefulWidget {
  final String managerId;

  const ManagerProfilePublicPage({super.key, required this.managerId});

  @override
  State<ManagerProfilePublicPage> createState() => _ManagerProfilePublicPageState();
}

class _ManagerProfilePublicPageState extends State<ManagerProfilePublicPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _managerData;

  @override
  void initState() {
    super.initState();
    _loadManagerData();
  }

  Future<void> _loadManagerData() async {
    setState(() => _isLoading = true);
    try {
      final data = await HostService.getManagerDetails(widget.managerId);
      if (mounted) {
        setState(() {
          _managerData = data;
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

    if (_managerData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Not Found')),
        body: const Center(child: Text('Could not load manager profile.')),
      );
    }

    final String name = _managerData!['full_name'] ?? 'Manager';
    final String email = _managerData!['email'] ?? 'Not specified';
    final String company = _managerData!['company_name'] ?? 'Independent';
    final String location = _managerData!['company_location'] ?? 'Location N/A';
    final String bio = _managerData!['bio'] ?? 'No bio provided.';
    final String? photoUrl = _managerData!['profile_photo'];

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
                  Text(
                    company,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
            _buildInfoRow(Icons.location_on_outlined, 'Base Location', location),
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

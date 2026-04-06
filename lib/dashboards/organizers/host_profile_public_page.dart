import 'package:flutter/material.dart';
import '../../services/host_service.dart';
import '../../../widgets/safe_avatar.dart';

class HostProfilePublicPage extends StatefulWidget {
  final String hostId;

  const HostProfilePublicPage({super.key, required this.hostId});

  @override
  State<HostProfilePublicPage> createState() => _HostProfilePublicPageState();
}

class _HostProfilePublicPageState extends State<HostProfilePublicPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _hostData;

  @override
  void initState() {
    super.initState();
    _loadHostData();
  }

  Future<void> _loadHostData() async {
    setState(() => _isLoading = true);
    try {
      // The `users` table holds both Manager and Host details
      final data = await HostService.getManagerDetails(widget.hostId);
      if (mounted) {
        setState(() {
          _hostData = data;
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

    if (_hostData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organizer Not Found')),
        body: const Center(child: Text('Could not load organizer profile.')),
      );
    }

    final String name = _hostData!['full_name'] ?? 'Event Organizer';
    final String email = _hostData!['email'] ?? 'Not specified';
    final String phoneNumber = _hostData!['phone_number'] ?? 'Not specified';
    final String bio = _hostData!['bio'] ?? 'No bio provided.';
    final String? photoUrl = _hostData!['profile_photo'];

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
                ],
              ),
            ),
            const Divider(height: 48),
            const Text(
              'Organizer Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, 'Phone Number', phoneNumber),
            const Divider(height: 48),
            const Text(
              'About the Organizer',
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

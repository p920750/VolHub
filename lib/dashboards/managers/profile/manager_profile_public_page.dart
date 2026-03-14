import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/host_service.dart';
import '../../../../widgets/safe_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagerProfilePublicPage extends StatefulWidget {
  final String managerId;

  const ManagerProfilePublicPage({super.key, required this.managerId});

  @override
  State<ManagerProfilePublicPage> createState() => _ManagerProfilePublicPageState();
}

class _ManagerProfilePublicPageState extends State<ManagerProfilePublicPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _managerData;
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadManagerData();
    _setupLiveListener();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _setupLiveListener() {
    _profileSubscription = HostService.getManagerDetailsStream(widget.managerId).listen((data) {
      if (data.isNotEmpty && mounted) {
        setState(() {
          _managerData = data.first;
          _isLoading = false;
        });
      }
    });
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch: $urlString')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching: $e')),
        );
      }
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
    final String phone = _managerData!['phone_number'] ?? 'Not specified';
    final String company = _managerData!['company_name'] ?? 'Independent';
    final String location = _managerData!['company_location'] ?? 'Location N/A';
    final String bio = _managerData!['bio'] ?? 'No bio provided.';
    final String? photoUrl = _managerData!['profile_photo'];
    final String? linkedinUrl = _managerData!['linkedin_url'];
    final List<String> certificates = (_managerData!['certificates'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

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
            _buildInfoRow(
              Icons.email_outlined, 
              'Email', 
              email,
              textColor: email != 'Not specified' ? Colors.blue : null,
              onTap: email != 'Not specified' 
                  ? () => _launchURL(Uri(scheme: 'mailto', path: email).toString())
                  : null,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone_outlined, 
              'Phone Number', 
              phone,
              onTap: phone != 'Not specified' 
                  ? () => _launchURL(Uri(scheme: 'tel', path: phone).toString())
                  : null,
            ),
            const SizedBox(height: 12),
            if (linkedinUrl != null && linkedinUrl.isNotEmpty) ...[
              _buildInfoRow(
                Icons.link, 
                'LinkedIn Profile', 
                linkedinUrl,
                textColor: Colors.blue,
                onTap: () => _launchURL(linkedinUrl),
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(Icons.location_on_outlined, 'Base Location', location),
            const Divider(height: 48),

            const Text(
              'Certificates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (certificates.isEmpty)
              const Text('No certificates uploaded', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final url = certificates[index];
                    final isPdf = url.toLowerCase().endsWith('.pdf');
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          if (isPdf) {
                            _launchURL(url);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog.fullscreen(
                                child: Stack(
                                  children: [
                                    Center(child: InteractiveViewer(child: Image.network(url))),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isPdf 
                            ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error)),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 48),
            const Text(
              'About Us',
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

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap, Color? textColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E4D40)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    value, 
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      decoration: textColor != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

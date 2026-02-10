import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import 'host_settings_page.dart';
import 'host_edit_profile_page.dart';

class HostProfilePage extends StatefulWidget {
  const HostProfilePage({super.key});

  @override
  State<HostProfilePage> createState() => _HostProfilePageState();
}

class _HostProfilePageState extends State<HostProfilePage> {
  late Future<Map<String, dynamic>?> _profileFuture;
  final Color primaryGreen = const Color(0xFF1E4D40);
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseService.getUserProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = SupabaseService.getUserProfile();
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final String? imageUrl = await SupabaseService.uploadProfileImage(
        File(image.path),
        SupabaseService.currentUser!.id,
      );

      if (imageUrl != null) {
        await SupabaseService.updateUserProfile({'profile_photo': imageUrl});
        await _refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final fullName = userData?['full_name'] ?? 'Alex Rivera';
        final profilePhoto = userData?['profile_photo'] ?? 'https://i.pravatar.cc/150?u=alex';
        final email = userData?['email'] ?? 'alex.rivera@zenith.com';
        final phone = userData?['phone_number'] ?? '+1 (555) 012-3456';

        return Scaffold(
          backgroundColor: const Color(0xFFF1F7F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Image.asset(
              'assets/images/logo_1.jpeg',
              height: 32,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fullName.split(' ')[0],
                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'HOST ACCOUNT',
                      style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isMobile = constraints.maxWidth < 800;
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 40, 
                        vertical: 24
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Cover Photo & Profile Photo
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: isMobile ? 140 : 180,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryGreen,
                                            const Color(0xFF2E6B5A),
                                          ],
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: GestureDetector(
                                            onTap: _pickAndUploadImage,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -40,
                                      left: isMobile ? 20 : 32,
                                      child: GestureDetector(
                                        onTap: _pickAndUploadImage,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  profilePhoto,
                                                  width: isMobile ? 100 : 120,
                                                  height: isMobile ? 100 : 120,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            if (_isUploading)
                                              const CircularProgressIndicator(color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 50),
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                                  child: isMobile 
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildMainProfileInfo(fullName, email, phone, userData?['address'], isMobile),
                                          const SizedBox(height: 24),
                                          _buildAboutMeSection(userData?['bio']),
                                          const SizedBox(height: 24),
                                          _buildStatsRow(isMobile),
                                          const SizedBox(height: 24),
                                          _buildRightSideActions(userData),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Left Side Info
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildMainProfileInfo(fullName, email, phone, userData?['address'], isMobile),
                                                const SizedBox(height: 32),
                                                _buildAboutMeSection(userData?['bio']),
                                                const SizedBox(height: 32),
                                                _buildStatsRow(isMobile),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 32),
                                          // Right Side Actions
                                          Expanded(
                                            flex: 2,
                                            child: _buildRightSideActions(userData),
                                          ),
                                        ],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMainProfileInfo(String fullName, String email, String phone, String? address, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Lead Event Organizer @ Zenith Events',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildProfileActionsRow(),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          _buildProfileActionsRow(),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge(Icons.email_outlined, email),
            _buildBadge(Icons.phone_outlined, phone),
            _buildBadge(Icons.location_on_outlined, address ?? 'New York, NY'),
            _buildBadge(Icons.language, 'zenithevents.com'),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileActionsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HostSettingsPage()),
            );
            _refreshProfile();
          },
          child: _buildSmallSecondaryButton('Settings'),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HostEditProfilePage()),
            );
            if (result == true) {
              _refreshProfile();
            }
          },
          child: _buildSmallPrimaryButton('Edit Profile'),
        ),
      ],
    );
  }

  Widget _buildAboutMeSection(String? bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Me',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          bio ?? 'Passionate event organizer with over 10 years of experience in managing high-profile corporate galas, music festivals, and tech conferences. I specialize in logistics and vendor management, ensuring every event is a masterpiece.',
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    return Row(
      children: [
        _buildStatCard('Total Events', '124'),
        const SizedBox(width: 8),
        _buildStatCard('Active Now', '12'),
        const SizedBox(width: 8),
        _buildStatCard('Managers Found', '450+'),
      ],
    );
  }

  // Removed _buildMobileActions as per user request

  Widget _buildRightSideActions(Map<String, dynamic>? userData) {
    final settings = userData?['settings'] as Map<String, dynamic>?;
    final bool notificationsEnabled = settings?['email_notifications'] == true || 
                                     settings?['push_notifications'] == true || 
                                     settings?['sms_alerts'] == true;

    return Column(
      children: [
        _buildSectionCard(
          'Account Security',
          [
            _buildSecurityItem('Two-Factor Auth', 'ON'),
            _buildSecurityItem('Notifications', notificationsEnabled ? 'Enabled' : 'Disabled'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          'Quick Actions',
          [
            _buildQuickAction('Change Password', onTap: () async {
               await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HostSettingsPage()),
              );
              _refreshProfile();
            }),
            _buildQuickAction('Update Billing'),
            _buildQuickAction('Deactivate Account', isDestructive: true),
          ],
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primaryGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label, 
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F7F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF031633),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSecondaryButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Color(0xFF2E6B5A), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSmallPrimaryButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF031633),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSmallSecondaryButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F5).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(label.contains('Auth') ? Icons.security : Icons.notifications_none, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: value == 'ON' || value == 'Enabled' ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text, {bool isDestructive = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap ?? () {},
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isDestructive ? Colors.red : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

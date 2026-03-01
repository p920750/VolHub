import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import 'host_settings_page.dart';
import 'host_edit_profile_page.dart';
import 'host_profile_provider.dart';

class HostProfilePage extends ConsumerStatefulWidget {
  const HostProfilePage({super.key});

  @override
  ConsumerState<HostProfilePage> createState() => _HostProfilePageState();
}

class _HostProfilePageState extends ConsumerState<HostProfilePage> {
  final Color primaryGreen = const Color(0xFF1E4D40);
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
        await ref.read(hostProfileProvider.notifier).updateProfile({'profile_photo': imageUrl});
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
    final profileAsync = ref.watch(hostProfileProvider);

    return profileAsync.when(
      data: (profile) => Scaffold(
        backgroundColor: const Color(0xFFF1F7F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
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
                    profile.name.split(' ')[0],
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
        body: LayoutBuilder(
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
                                          profile.profilePhoto,
                                          width: isMobile ? 100 : 120,
                                          height: isMobile ? 100 : 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.account_circle,
                                              size: isMobile ? 100 : 120,
                                              color: Colors.grey,
                                            );
                                          },
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
                                  _buildMainProfileInfo(profile, isMobile),
                                  const SizedBox(height: 24),
                                  _buildAboutMeSection(profile.bio),
                                  const SizedBox(height: 24),
                                  _buildStatsRow(isMobile),
                                  const SizedBox(height: 24),
                                  _buildRightSideActions(profile),
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
                                        _buildMainProfileInfo(profile, isMobile),
                                        const SizedBox(height: 32),
                                        _buildAboutMeSection(profile.bio),
                                        const SizedBox(height: 32),
                                        _buildStatsRow(isMobile),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  // Right Side Actions
                                  Expanded(
                                    flex: 2,
                                    child: _buildRightSideActions(profile),
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
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildMainProfileInfo(HostProfile profile, bool isMobile) {
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
                    profile.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Lead Event Organizer @ VolHub',
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
            _buildBadge(Icons.email_outlined, profile.email),
            _buildBadge(Icons.phone_outlined, profile.phone),
            _buildBadge(Icons.location_on_outlined, profile.address),
            _buildBadge(Icons.language, 'volhub.com'),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HostSettingsPage()),
            );
          },
          child: _buildSmallSecondaryButton('Settings'),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HostEditProfilePage()),
            );
          },
          child: _buildSmallPrimaryButton('Edit Profile'),
        ),
      ],
    );
  }

  Widget _buildAboutMeSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Me',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          bio,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    return Row(
      children: [
        _buildStatCard('Total Requests', '124'),
        const SizedBox(width: 8),
        _buildStatCard('Active Now', '12'),
        const SizedBox(width: 8),
        _buildStatCard('Managers Found', '450+'),
      ],
    );
  }

  Widget _buildRightSideActions(HostProfile profile) {
    return Column(
      children: [
        _buildSectionCard(
          'Account Security',
          [
            _buildSecurityItem('Two-Factor Auth', 'ON'),
            _buildSecurityItem('Notifications', 'Enabled'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          'Quick Actions',
          [
            _buildQuickAction('Change Password', onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HostSettingsPage()),
              );
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
        if (context.mounted) {
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

import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class HostSettingsPage extends StatefulWidget {
  const HostSettingsPage({super.key});

  @override
  State<HostSettingsPage> createState() => _HostSettingsPageState();
}

class _HostSettingsPageState extends State<HostSettingsPage> {
  final Color primaryGreen = const Color(0xFF1E4D40);
  final Color sectionBg = const Color(0xFFF1F7F5);
  
  bool _isSaving = false;
  bool _isLoading = true;

  // Settings State
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsAlerts = false;
  bool publicProfile = true;
  bool darkPreview = false;
  String selectedLanguage = 'English (US)';
  String selectedTimeZone = '(GMT-05:00) Eastern Time';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userData = await SupabaseService.getUserProfile();
      if (userData != null && userData['settings'] != null) {
        final settings = userData['settings'] as Map<String, dynamic>;
        setState(() {
          emailNotifications = settings['email_notifications'] ?? true;
          pushNotifications = settings['push_notifications'] ?? true;
          smsAlerts = settings['sms_alerts'] ?? false;
          publicProfile = settings['public_profile'] ?? true;
          darkPreview = settings['dark_preview'] ?? false;
          selectedLanguage = settings['language'] ?? 'English (US)';
          selectedTimeZone = settings['time_zone'] ?? '(GMT-05:00) Eastern Time';
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _anyNotificationsEnabled => emailNotifications || pushNotifications || smsAlerts;

  void _showPasswordChangeDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isVerifying = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                final current = currentPasswordController.text;
                final newPass = newPasswordController.text;
                final confirm = confirmPasswordController.text;

                if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  setDialogState(() => errorMessage = 'Please fill all fields');
                  return;
                }
                if (newPass != confirm) {
                  setDialogState(() => errorMessage = 'Passwords do not match');
                  return;
                }
                if (newPass.length < 6) {
                   setDialogState(() => errorMessage = 'Password must be at least 6 characters');
                   return;
                }

                setDialogState(() {
                  isVerifying = true;
                  errorMessage = null;
                });

                final verified = await SupabaseService.verifyCurrentPassword(current);
                if (!verified) {
                  if (context.mounted) {
                    setDialogState(() {
                      isVerifying = false;
                      errorMessage = 'Incorrect current password';
                    });
                  }
                  return;
                }

                try {
                  await SupabaseService.updatePassword(newPass);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() {
                      isVerifying = false;
                      errorMessage = 'Error: $e';
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isVerifying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Change Password', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 150,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.grey),
          label: const Text('Back to Profile', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () async {
                setState(() => _isSaving = true);
                try {
                  final settings = {
                    'email_notifications': emailNotifications,
                    'push_notifications': pushNotifications,
                    'sms_alerts': smsAlerts,
                    'public_profile': publicProfile,
                    'dark_preview': darkPreview,
                    'language': selectedLanguage,
                    'time_zone': selectedTimeZone,
                  };
                  await SupabaseService.updateUserProfile({'settings': settings});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
              label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF031633),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 40,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 700;
                
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text('Manage your account preferences and security.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 32),
                      _buildNotificationsCard(),
                      const SizedBox(height: 24),
                      _buildSecurityCard(),
                      const SizedBox(height: 24),
                      _buildPreferencesCard(),
                      const SizedBox(height: 24),
                      _buildDangerZoneCard(),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Manage your account preferences and security.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildNotificationsCard(),
                              const SizedBox(height: 24),
                              _buildPreferencesCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            children: [
                              _buildSecurityCard(),
                              const SizedBox(height: 24),
                              _buildDangerZoneCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _buildCard(
      title: 'Notifications',
      icon: Icons.notifications_none,
      children: [
        _buildToggleTile(
          'Email Notifications', 
          'Receive daily updates via email.', 
          emailNotifications, 
          (v) => setState(() => emailNotifications = v)
        ),
        _buildToggleTile(
          'Push Notifications', 
          'Alerts on your browser/desktop.', 
          pushNotifications, 
          (v) => setState(() => pushNotifications = v)
        ),
        _buildToggleTile(
          'SMS Alerts', 
          'Urgent updates to your phone.', 
          smsAlerts, 
          (v) => setState(() => smsAlerts = v)
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return _buildCard(
      title: 'Security & Privacy',
      icon: Icons.security_outlined,
      children: [
        _buildActionTile(
          'Change Password', 
          'Update your account password regularly.', 
          Icons.lock_outline,
          onTap: _showPasswordChangeDialog,
        ),
        _buildStatusTile(
          'Notifications', 
          'Stay updated with your activities.', 
          Icons.notifications_none,
          _anyNotificationsEnabled ? 'ENABLED' : 'DISABLED',
          color: _anyNotificationsEnabled ? Colors.green : Colors.red,
        ),
        _buildStatusTile(
          'Two-Factor Authentication', 
          'Add an extra layer of security.', 
          Icons.smartphone_outlined,
          'ACTIVE',
        ),
        _buildToggleTile(
          'Public Profile', 
          'Allow others to see your events.', 
          publicProfile, 
          (v) => setState(() => publicProfile = v)
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return _buildCard(
      title: 'Preferences',
      icon: Icons.language_outlined,
      children: [
        const Text('DISPLAY LANGUAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        _buildDropdown(['English (US)', 'Spanish', 'French'], selectedLanguage, (v) => setState(() => selectedLanguage = v!)),
        const SizedBox(height: 24),
        const Text('TIME ZONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        _buildDropdown(['(GMT-05:00) Eastern Time', '(GMT-08:00) Pacific Time', '(GMT+00:00) UTC'], selectedTimeZone, (v) => setState(() => selectedTimeZone = v!)),
        const SizedBox(height: 24),
        _buildToggleTile(
          'Dark Mode (Preview)', 
          '', 
          darkPreview, 
          (v) => setState(() => darkPreview = v),
          icon: Icons.dark_mode_outlined,
        ),
      ],
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_reset_outlined, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('These actions are permanent and cannot be undone.', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildDangerButton('Delete Account'),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Archive All Event Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sectionBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, Function(bool) onChanged, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeColor: primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile(String title, String subtitle, IconData icon, String status, {Color color = Colors.green}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDangerButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

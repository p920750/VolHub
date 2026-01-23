import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;

  // Privacy
  bool showPhone = true;
  bool showEmail = true;

  // Preferences
  bool interestedInPaid = true;
  bool interestedInUnpaid = true;

  // Availability
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('settings')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            showPhone = settings['show_phone'] ?? true;
            showEmail = settings['show_email'] ?? true;
            interestedInPaid = settings['interested_paid'] ?? true;
            interestedInUnpaid = settings['interested_unpaid'] ?? true;
            isAvailable = settings['is_available'] ?? true;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    // Optimistic update
    setState(() {
      if (key == 'show_phone') showPhone = value;
      if (key == 'show_email') showEmail = value;
      if (key == 'interested_paid') interestedInPaid = value;
      if (key == 'interested_unpaid') interestedInUnpaid = value;
      if (key == 'is_available') isAvailable = value;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Prepare full JSON object to merge/upsert
      // Note: Supabase JSONB updates can be partial if using deep merge, 
      // but standard update replaces the column value if not careful.
      // Easiest is to read-modify-write or use a postgres function. 
      // For simplicity/safety without custom functions, we'll construct the whole object 
      // based on current local state since we just fetched it.
      
      final newSettings = {
        'show_phone': showPhone,
        'show_email': showEmail,
        'interested_paid': interestedInPaid,
        'interested_unpaid': interestedInUnpaid,
        'is_available': isAvailable,
      };

      await Supabase.instance.client
          .from('users')
          .update({'settings': newSettings})
          .eq('id', user.id);
          
    } catch (e) {
      debugPrint('Error updating setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _checkboxTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      controlAffinity: ListTileControlAffinity.trailing,
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
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          _sectionHeader("PRIVACY"),
          _switchTile(
            "Show Phone Number", 
            "Allow organizations to see your phone number", 
            showPhone, 
            (val) => _updateSetting('show_phone', val),
          ),
          _switchTile(
            "Show Email Address", 
            "Allow organizations to see your email", 
            showEmail, 
            (val) => _updateSetting('show_email', val),
          ),
          const Divider(),

          _sectionHeader("OPPORTUNITY PREFERENCES"),
          _checkboxTile(
            "Paid Opportunities", 
            interestedInPaid, 
            (val) => _updateSetting('interested_paid', val!),
          ),
          _checkboxTile(
            "Unpaid / Volunteer", 
            interestedInUnpaid, 
            (val) => _updateSetting('interested_unpaid', val!),
          ),
          const Divider(),

          _sectionHeader("AVAILABILITY"),
          _switchTile(
            "Available for new tasks", 
            "Turn off to hide your profile from search results", 
            isAvailable, 
            (val) => _updateSetting('is_available', val),
          ),
        ],
      ),
    );
  }
}

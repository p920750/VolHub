import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'profile_details_page.dart';
import 'settings_page.dart'; // Added

import 'volunteer_home_page.dart'; // Added

class VolunteerProfilePage extends StatefulWidget {
  const VolunteerProfilePage({super.key});

  @override
  State<VolunteerProfilePage> createState() => _VolunteerProfilePageState();
}

class _VolunteerProfilePageState extends State<VolunteerProfilePage> {
  // ... (existing variables)
  File? _profileImage;
  String? avatarUrl; 
  String email = ''; 
  String fullName = ''; 
  String phone = '';
  bool showPhone = true;
  bool showEmail = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Reload profile when returning from details page
  void _refreshProfile() {
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        final settings = data['settings'] as Map<String, dynamic>?;
        setState(() {
          if (data['full_name'] != null) fullName = data['full_name'];
          if (data['phone_number'] != null) phone = data['phone_number'];
          if (data['profile_photo'] != null) avatarUrl = data['profile_photo'];
          email = user.email ?? '';

          if (settings != null) {
            showPhone = settings['show_phone'] ?? true;
            showEmail = settings['show_email'] ?? true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }
  
  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _profileImage = file;
      });

      // Upload to Supabase
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading profile photo...')),
          );
        }

        final url = await SupabaseService.uploadProfileImage(file, userId);
        
        if (url != null) {
           setState(() {
             avatarUrl = url;
           });
           await _updateProfile({'profile_photo': url});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // No standard AppBar, we build a custom header
      body: SingleChildScrollView(
        child: Column(
          children: [
            /* ================= HEADER SECTION ================= */
            SizedBox(
              height: 250, // 180 (bg) + 70 (overflow approx)
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Background Color Block
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFD6C8FF),
                  ),
                  
                  // Back Button (Top Left)
                  Positioned(
                    top: 40,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const VolunteerHomePage()),
                          );
                        }
                      },
                    ),
                  ),

                  
                  // Profile Avatar
                  Positioned(
                    top: 115, // 180 - 65(radius)
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey.shade300,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      width: 130,
                                      height: 130,
                                      fit: BoxFit.cover,
                                    )
                                  : (avatarUrl != null && avatarUrl!.isNotEmpty
                                        ? Image.network(
                                            avatarUrl!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 70,
                                            color: Colors.grey.shade600,
                                          )),
                            ),
                          ),
                        ),
                        
                        // Edit Icon
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // const SizedBox(height: 70), // Removed as we used SizedBox height 250 for the stack area

            /* ================= USER INFO ================= */
            Text(
              fullName.isNotEmpty ? fullName : 'Volunteer Name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Phone
            if (showPhone && phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      phone, 
                      style: const TextStyle(color: Colors.black87, fontSize: 15, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),

             // Email
             if (showEmail && email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        email, 
                        style: const TextStyle(color: Colors.black87, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

            /* ================= MENU ITEMS ================= */
            


            // Profile Details
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.black),
              title: const Text("Profile details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileDetailsPage()),
                );
                _refreshProfile(); // Refresh on return
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // Settings
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.black),
            title: const Text("Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // Log out
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text("Log out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () async {
                 await Supabase.instance.client.auth.signOut();
                 if (mounted) {
                   Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                 }
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';

class HostEditProfilePage extends StatefulWidget {
  const HostEditProfilePage({super.key});

  @override
  State<HostEditProfilePage> createState() => _HostEditProfilePageState();
}

class _HostEditProfilePageState extends State<HostEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final Color primaryGreen = const Color(0xFF1E4D40);
  final ImagePicker _picker = ImagePicker();
  
  String? _profilePhotoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userData = await SupabaseService.getUserProfile();
      if (userData != null) {
        setState(() {
          _nameController.text = userData['full_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone_number'] ?? '';
          _addressController.text = userData['address'] ?? 'New York, NY';
          _bioController.text = userData['bio'] ?? '';
          _profilePhotoUrl = userData['profile_photo'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
        setState(() => _profilePhotoUrl = imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _profilePhotoUrl = null);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile_photo': _profilePhotoUrl,
      };

      await SupabaseService.updateUserProfile(updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(color: Color(0xFF031633), fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF031633),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    children: [
                      Icon(Icons.save_outlined, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update your personal and professional information.', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),
              
              // Profile Photo Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _profilePhotoUrl != null
                              ? Image.network(_profilePhotoUrl!, width: 100, height: 100, fit: BoxFit.cover)
                              : Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.person, size: 50, color: Colors.grey)),
                        ),
                      ),
                      if (_isUploading) const CircularProgressIndicator(),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('JPG, GIF or PNG. Max size 2MB.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: const Text('Change Photo', style: TextStyle(color: Color(0xFF2E6B5A), fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _removePhoto,
                            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Basic Information
              const Text('BASIC INFORMATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E4D40))),
              const SizedBox(height: 20),
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              
              const SizedBox(height: 32),
              
              // Contact & Location
              const Text('CONTACT & LOCATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E4D40))),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildTextField('Email Address', _emailController, Icons.email_outlined),
                      const SizedBox(height: 20),
                      _buildTextField('Phone Number', _phoneController, Icons.phone_outlined),
                      const SizedBox(height: 20),
                      _buildTextField('Location', _addressController, Icons.location_on_outlined),
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Email Address', _emailController, Icons.email_outlined)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTextField('Phone Number', _phoneController, Icons.phone_outlined)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Location', _addressController, Icons.location_on_outlined)),
                        const Expanded(child: SizedBox()), // Placeholder to match layout
                      ],
                    ),
                  ],
                );
              }),

              const SizedBox(height: 32),

              // Professional Bio
              const Text('Professional Bio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E4D40))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E6B5A))),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E6B5A))),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Field cannot be empty';
            return null;
          },
        ),
      ],
    );
  }
}

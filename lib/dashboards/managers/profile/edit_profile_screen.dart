import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool firstTime;
  const EditProfileScreen({super.key, this.firstTime = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _isInitialized = false;
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _certNameController;
  late TextEditingController _certDateController;

  @override
  void initState() {
    super.initState();
    // Controllers initialized in build when data is available
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _roleController.dispose();
      _bioController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      _locationController.dispose();
      _linkedinController.dispose();
      _certNameController.dispose();
      _certDateController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Get current profile from provider value (assuming it's loaded if we are here)
    final profileAsync = ref.read(userProfileProvider);
    if (!profileAsync.hasValue) return;
    
    final currentProfile = profileAsync.value!;
    
    final updatedProfile = currentProfile.copyWith(
      name: _nameController.text,
      role: _roleController.text,
      bio: _bioController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      location: _locationController.text,
      linkedinUrl: _linkedinController.text,
      certName: _certNameController.text,
      certIssuedDate: _certDateController.text,
    );
    
    await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_isInitialized) {
          _nameController = TextEditingController(text: widget.firstTime ? '' : profile.name);
          _roleController = TextEditingController(text: widget.firstTime ? '' : profile.role);
          _bioController = TextEditingController(text: widget.firstTime ? '' : profile.bio);
          _emailController = TextEditingController(text: widget.firstTime ? '' : profile.email);
          _phoneController = TextEditingController(text: widget.firstTime ? '' : profile.phone);
          _locationController = TextEditingController(text: widget.firstTime ? '' : profile.location);
          _linkedinController = TextEditingController(text: widget.firstTime ? '' : profile.linkedinUrl);
          _certNameController = TextEditingController(text: widget.firstTime ? '' : profile.certName);
          _certDateController = TextEditingController(text: widget.firstTime ? '' : profile.certIssuedDate);
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            actions: [
              TextButton(
                onPressed: _saveProfile,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(profile.profileImage),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Photo upload coming soon!')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField('Full Name', _nameController),
                _buildTextField('Role', _roleController),
                _buildTextField('Bio', _bioController, maxLines: 3),
                _buildTextField('Email', _emailController),
                _buildTextField('Phone', _phoneController),
                _buildTextField('Location', _locationController),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                _buildTextField('LinkedIn Profile URL', _linkedinController, icon: Icons.link),
                _buildTextField('Certification Name', _certNameController, icon: Icons.workspace_premium),
                _buildTextField('Issued Date', _certDateController, icon: Icons.calendar_today),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveProfile,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

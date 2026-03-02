import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_provider.dart';
import 'package:main_volhub/widgets/safe_avatar.dart';

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
  late TextEditingController _companyNameController;
  late TextEditingController _companyLocationController;
  late TextEditingController _linkedinController;
  late TextEditingController _certNameController;
  late TextEditingController _certDateController;
  late TextEditingController _categoryController;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _roleController.dispose();
      _bioController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      _companyNameController.dispose();
      _companyLocationController.dispose();
      _linkedinController.dispose();
      _certNameController.dispose();
      _certDateController.dispose();
      _categoryController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final profileAsync = ref.read(userProfileProvider);
    if (!profileAsync.hasValue) return;
    
    final currentProfile = profileAsync.value!;
    
    final updatedProfile = currentProfile.copyWith(
      name: _nameController.text,
      role: _roleController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      companyName: _companyNameController.text,
      companyLocation: _companyLocationController.text,
      linkedinUrl: _linkedinController.text,
      certName: _certNameController.text,
      certIssuedDate: _certDateController.text,
      categories: _categories,
    );
    
    await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    if (mounted) Navigator.pop(context);
  }

  void _addCategory(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      if (!_categories.contains(value.trim())) {
        _categories.insert(0, value.trim());
      }
      _categoryController.clear();
    });
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
          _companyNameController = TextEditingController(text: widget.firstTime ? '' : profile.companyName);
          _companyLocationController = TextEditingController(text: widget.firstTime ? '' : profile.companyLocation);
          _linkedinController = TextEditingController(text: widget.firstTime ? '' : profile.linkedinUrl);
          _certNameController = TextEditingController(text: widget.firstTime ? '' : profile.certName);
          _certDateController = TextEditingController(text: widget.firstTime ? '' : profile.certIssuedDate);
          _categories = List.from(profile.categories);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      SafeAvatar(
                        radius: 50,
                        imageUrl: profile.profileImage,
                        name: profile.name,
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
                _buildTextField('Company Name', _companyNameController, icon: Icons.business),
                _buildTextField('Company Location', _companyLocationController, icon: Icons.location_on),
                
                const SizedBox(height: 24),
                const Text('Company Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: 'Add category and press Enter',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: _addCategory,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _categories.map((category) => Chip(
                    label: Text(category),
                    onDeleted: () {
                      setState(() {
                        _categories.remove(category);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  )).toList(),
                ),

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

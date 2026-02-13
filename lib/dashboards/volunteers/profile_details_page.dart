import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/supabase_service.dart';
import '../../screens/identity_verification_page.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  // Verification states: 'unverified', 'pending', 'verified'
  String verificationStatus = 'unverified';

  String? phoneError;
  String? skillsError;
  String? interestsError;
  String? addressError;
  
  // Profile Photo & Completion
  File? _profileImage;
  String? avatarUrl;
  double profileCompletion = 0.0;
  final ImagePicker _picker = ImagePicker();

  String phone = '';
  String address = '';
  String fullName = ''; // Needed for completion calc
  String email = ''; // Needed for completion calc
  String bio = '';

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus = FocusNode();

  bool editPhone = false;
  bool editAddress = false;
  bool editBio = false;

  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  final List<String> skills = [];
  final List<String> interests = [];
  final List<PlatformFile> certificates = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && editPhone) {
        setState(() {
          phone = _phoneController.text;
          editPhone = false;
        });
        _validateProfile();
        _calculateProfileCompletion();
      }
    });

    _addressFocus.addListener(() {
      if (!_addressFocus.hasFocus && editAddress) {
        setState(() {
          address = _addressController.text;
          editAddress = false;
        });
        _validateProfile();
        _calculateProfileCompletion();
      }
    });

    _bioFocus.addListener(() {
      if (!_bioFocus.hasFocus && editBio) {
        setState(() {
          bio = _bioController.text;
          editBio = false;
        });
        _validateProfile();
        _calculateProfileCompletion();
      }
    });
  }

  /* ---------------- PROFILE PHOTO & COMPLETION ---------------- */
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
      _calculateProfileCompletion();

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
           await _updateProfile({'avatar_url': url});
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

  void _calculateProfileCompletion() {
    int completed = 0;
    // We check 9 fields
    if (_profileImage != null || (avatarUrl != null && avatarUrl!.isNotEmpty)) completed++;
    if (email.isNotEmpty) completed++;
    if (fullName.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (address.isNotEmpty) completed++;
    if (skills.isNotEmpty) completed++;
    if (interests.isNotEmpty) completed++;
    if (certificates.isNotEmpty) completed++;
    if (bio.isNotEmpty) completed++;

    setState(() {
      profileCompletion = (completed / 9) * 100;
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      setState(() {
         email = user.email ?? '';
         fullName = user.userMetadata?['full_name'] ?? ''; // Best effort
      });

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          verificationStatus = data['verification_status'] ?? 'unverified';
          if (data['full_name'] != null) fullName = data['full_name'];
          if (data['phone'] != null) phone = data['phone'];
          if (data['address'] != null) address = data['address'];
          if (data['bio'] != null) bio = data['bio'];
          if (data['avatar_url'] != null) avatarUrl = data['avatar_url'];
          
          if (data['skills'] != null) {
            skills.clear();
            skills.addAll(List<String>.from(data['skills']));
          }
          if (data['interests'] != null) {
            interests.clear();
            interests.addAll(List<String>.from(data['interests']));
          }
          
          _phoneController.text = phone;
          _addressController.text = address;
          _bioController.text = bio;
          _isLoading = false;
        });
        _validateProfile();
        _calculateProfileCompletion();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      setState(() => _isLoading = false);
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
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _validPhone(String value) {
    return RegExp(r'^\d{10}$').hasMatch(value);
  }
  
  bool _onlyLetters(String value) {
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(value);
  }

  void _validateProfile() {
    setState(() {
      phoneError = phone.isEmpty
          ? 'Phone number is required'
          : !_validPhone(phone)
          ? 'Enter 10 digit number'
          : null;

      skillsError = skills.isEmpty ? 'Add at least one skill' : null;
      interestsError = interests.isEmpty ? 'Add at least one interest' : null;
    });
  }

  /* ---------------- CERTIFICATE PICK ---------------- */
  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() {
      certificates.insert(0, result.files.first);
    });
    _calculateProfileCompletion();
  }
  
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: child,
    );
  }

  Widget _inlineEditableField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    int? maxLines,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isEditing
              ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: maxLines,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _validateProfile(),
                  onEditingComplete: () {
                    focusNode.unfocus();
                    onSave();
                  },
                )
              : Text(
                  controller.text.isEmpty ? 'Not set' : controller.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: controller.text.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  String _getEmoji(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('code') || lower.contains('program') || lower.contains('dev')) return '💻';
    if (lower.contains('movie') || lower.contains('film') || lower.contains('cinema')) return '🎬';
    if (lower.contains('music') || lower.contains('song')) return '🎵';
    if (lower.contains('read') || lower.contains('book')) return '📚';
    if (lower.contains('paint') || lower.contains('art') || lower.contains('draw')) return '🎨';
    if (lower.contains('sport') || lower.contains('game') || lower.contains('play')) return '⚽';
    if (lower.contains('food') || lower.contains('cook')) return '🍳';
    if (lower.contains('travel')) return '✈️';
    if (lower.contains('photo')) return '📷';
    if (lower.contains('garden') || lower.contains('plant')) return '🌿';
    if (lower.contains('dance')) return '💃';
    if (lower.contains('write')) return '✍️';
    if (lower.contains('swim')) return '🏊';
    if (lower.contains('run')) return '🏃';
    if (lower.contains('animal') || lower.contains('pet')) return '🐾';
    return '🔹'; // Default
  }

  Widget _chipList(List<String> items, void Function(int) onRemove) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final text = items[i];
        final emoji = _getEmoji(text);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$emoji $text", style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    onRemove(i);
                    _validateProfile();
                    _calculateProfileCompletion();
                  });
                },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /* ================= COMPLETION & PHOTO HEADER ================= */
            _card(
              child: Row(
                 children: [
                    Stack(
                      children: [
                         Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey.shade200,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(_profileImage!, fit: BoxFit.cover, width: 70, height: 70)
                                  : (avatarUrl != null && avatarUrl!.isNotEmpty
                                      ? Image.network(avatarUrl!, fit: BoxFit.cover, width: 70, height: 70)
                                      : const Icon(Icons.person, color: Colors.grey)),
                            ),
                          ),
                         ),
                         Positioned(
                           bottom: 0,
                           right: 0,
                           child: InkWell(
                             onTap: _pickProfileImage,
                             child: const CircleAvatar(
                               radius: 12,
                               backgroundColor: Colors.black,
                               child: Icon(Icons.edit, size: 10, color: Colors.white),
                             ),
                           ),
                         ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text("Profile Completeness", style: TextStyle(fontWeight: FontWeight.w600)),
                           const SizedBox(height: 8),
                           LinearProgressIndicator(
                             value: profileCompletion / 100,
                             backgroundColor: Colors.grey.shade200,
                             color: Colors.green,
                             minHeight: 8,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           const SizedBox(height: 6),
                           Text("${profileCompletion.toInt()}% Completed", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                 ],
              ),
            ),
            
            /* ================= PERSONAL INFO ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _inlineEditableField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    isEditing: editPhone,
                    errorText: phoneError,
                    onEdit: () {
                       _phoneController.text = phone;
                       setState(() => editPhone = true);
                       WidgetsBinding.instance.addPostFrameCallback((_) => _phoneFocus.requestFocus());
                    },
                    onSave: () {
                      setState(() {
                        phone = _phoneController.text;
                        editPhone = false;
                      });
                      _updateProfile({'phone': phone});
                      _validateProfile();
                    }
                  ),

                  _inlineEditableField(
                    label: 'Address',
                    controller: _addressController,
                    focusNode: _addressFocus,
                    isEditing: editAddress,
                    maxLines: null, // multiline
                    onEdit: () {
                       _addressController.text = address;
                       setState(() => editAddress = true);
                       WidgetsBinding.instance.addPostFrameCallback((_) => _addressFocus.requestFocus());
                    },
                    onSave: () {
                       setState(() {
                         address = _addressController.text;
                         editAddress = false;
                       });
                       _updateProfile({'address': address});
                       _validateProfile();
                    }
                  ),
                  _inlineEditableField(
                    label: 'Bio',
                    controller: _bioController,
                    focusNode: _bioFocus,
                    isEditing: editBio,
                    maxLines: 4, // multiline
                    onEdit: () {
                       _bioController.text = bio;
                       setState(() => editBio = true);
                       WidgetsBinding.instance.addPostFrameCallback((_) => _bioFocus.requestFocus());
                    },
                    onSave: () {
                       setState(() {
                         bio = _bioController.text;
                         editBio = false;
                       });
                       _updateProfile({'bio': bio});
                       _validateProfile();
                    }
                  ),
                ],
              ),
            ),

            /* ================= SKILLS ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Skills',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      hintText: 'Add skill',
                      suffixIcon: Icon(Icons.add),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (v) {
                      if (v.isEmpty || !_onlyLetters(v)) return;

                      setState(() {
                        skills.insert(0, v);
                        _skillController.clear();
                      });
                      _updateProfile({'skills': skills});
                      _validateProfile(); 
                    },
                  ),
                  const SizedBox(height: 16),
                  _chipList(skills, (i) { 
                    setState(() => skills.removeAt(i));
                    _updateProfile({'skills': skills});
                  }),
                  if (skillsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        skillsError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            /* ================= INTERESTS ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      hintText: 'Add interest',
                      suffixIcon: Icon(Icons.add),
                       border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                       contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (v) {
                      if (v.isEmpty || !_onlyLetters(v)) return;
                      setState(() {
                        interests.insert(0, v);
                        _interestController.clear();
                      });
                      _updateProfile({'interests': interests});
                      _validateProfile();
                    },
                  ),
                  const SizedBox(height: 16),
                  _chipList(interests, (i) {
                    setState(() => interests.removeAt(i));
                    _updateProfile({'interests': interests});
                  }),
                  if (interestsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        interestsError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            /* ================= CERTIFICATES ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Certificates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Certificates'),
                    onPressed: _pickCertificate,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(certificates.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    certificates[i].name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => certificates.removeAt(i));
                                  },
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            
            /* ================= IDENTITY VERIFICATION ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Identity Verification',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      if (verificationStatus == 'verified')
                        const Icon(Icons.check_circle, color: Colors.green)
                      else if (verificationStatus == 'pending')
                        Icon(Icons.hourglass_full, color: Colors.orange.shade400),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (verificationStatus == 'verified')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.green),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Identity Verified',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Your identity have been verified.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (verificationStatus == 'pending')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verification Pending',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Your submitted document is under review.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'Upload your Aadhaar card to become an official volunteer and get a verified badge.',
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const IdentityVerificationPage(),
                                ),
                              );
                              
                              if (result == true) {
                                setState(() {
                                  verificationStatus = 'pending';
                                });
                                // User metadata is already updated in IdentityVerificationPage
                                if(mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Document submitted successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Aadhaar Card'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF214E34),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

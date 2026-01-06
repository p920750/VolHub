import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class VolunteerProfilePage extends StatefulWidget {
  const VolunteerProfilePage({super.key});

  @override
  State<VolunteerProfilePage> createState() => _VolunteerProfilePageState();
}

class _VolunteerProfilePageState extends State<VolunteerProfilePage> {
  String selectedCountryCode = '+91';
  bool isCountryMenuOpen = false;
  // final List<String> countryCodes = ['+91', '+1', '+44', '+61'];

  String? fullNameError;
  String? phoneError;
  String? skillsError;
  String? interestsError;
  String? profileImageError;

  File? _profileImage;
  String email = 'praveenrajan@gmail.com';
  double profileCompletion = 0.0;
  String fullName = '';
  String phone = '';
  String address = '';

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool editFullName = false;
  bool editPhone = false;
  bool editAddress = false;

  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  final List<String> skills = [];
  final List<String> interests = [];
  final List<PlatformFile> certificates = [];

  final ImagePicker _picker = ImagePicker();

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
      _validateProfile();
      _calculateProfileCompletion();
    }
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
    _validateProfile();
    _calculateProfileCompletion();
  }

  void _calculateProfileCompletion() {
    int completed = 0;

    if (_profileImage != null) completed++;
    if (email.isNotEmpty) completed++;
    if (fullName.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (address.isNotEmpty) completed++;
    if (skills.isNotEmpty) completed++;
    if (interests.isNotEmpty) completed++;
    if (certificates.isNotEmpty) completed++;

    setState(() {
      profileCompletion = (completed / 8) * 100;
    });
  }

  bool _onlyLetters(String value) {
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(value);
  }

  bool _validPhone(String value) {
    return RegExp(r'^\d{10}$').hasMatch(value);
  }

  void _validateProfile() {
    setState(() {
      fullNameError = fullName.isEmpty
          ? 'Full name is required'
          : !_onlyLetters(fullName)
          ? 'Only alphabets allowed'
          : null;

      phoneError = phone.isEmpty
          ? 'Phone number is required'
          : !_validPhone(phone)
          ? 'Enter 10 digit number'
          : null;

      skillsError = skills.isEmpty ? 'Add at least one skill' : null;

      interestsError = interests.isEmpty ? 'Add at least one interest' : null;

      profileImageError = _profileImage == null
          ? 'Profile photo is required'
          : null;
    });
  }

  // Future<void> _showCountryCodeMenu(BuildContext context) async {
  //   setState(() => isCountryMenuOpen = true);

  //   final RenderBox button = context.findRenderObject() as RenderBox;
  //   final RenderBox overlay =
  //       Overlay.of(context).context.findRenderObject() as RenderBox;

  //   final Offset buttonPosition = button.localToGlobal(
  //     Offset.zero,
  //     ancestor: overlay,
  //   );

  //   final RelativeRect position = RelativeRect.fromLTRB(
  //     buttonPosition.dx,
  //     buttonPosition.dy + button.size.height + 6, // 🔑 BELOW THE BUTTON
  //     overlay.size.width - buttonPosition.dx - button.size.width,
  //     overlay.size.height - buttonPosition.dy,
  //   );

  //   final selected = await showMenu<String>(
  //     context: context,
  //     position: position,
  //     color: Colors.white,
  //     elevation: 6,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     items: countryCodes.map((code) {
  //       return PopupMenuItem<String>(
  //         value: code,
  //         height: 42,
  //         child: Center(
  //           child: Text(
  //             code,
  //             style: const TextStyle(fontSize: 14, color: Colors.black),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );

  //   if (selected != null) {
  //     setState(() {
  //       selectedCountryCode = selected;
  //     });
  //   }

  //   setState(() => isCountryMenuOpen = false);
  // }

  /* ---------------- COMMON CARD ---------------- */

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  /* ---------------- INLINE EDITABLE FIELD ---------------- */

  Widget _inlineEditableField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            // const Spacer(), //space between label and edit button
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity, // ✅ fixed width
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
                  onChanged: (_) {
                    _validateProfile();
                  },

                  onEditingComplete: () {
                    focusNode.unfocus();
                    onSave();
                  },
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black, // 🔑 FORCE BLACK
                  ),
                ),
        ),
        if ((label == 'Full Name' && fullNameError != null) ||
            (label == 'Phone Number' && phoneError != null))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label == 'Full Name' ? fullNameError! : phoneError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  /* ---------------- CHIP LIST ---------------- */

  Widget _chipList(List<String> items, void Function(int) onRemove) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // ✅ SAFE replacement
            children: [
              Text(items[i], style: const TextStyle(fontSize: 14)),
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

  /* ---------------- BUILD ---------------- */

  @override
  void initState() {
    super.initState();

    _fullNameFocus.addListener(() {
      if (!_fullNameFocus.hasFocus && editFullName) {
        setState(() {
          fullName = _fullNameController.text;
          editFullName = false;
        });
        _validateProfile();
        _calculateProfileCompletion();
      }
    });

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
    _validateProfile();
    _calculateProfileCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /* ================= PROFILE HEADER ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 🔑 important
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 85,
                            backgroundColor: Colors.grey.shade300,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      width: 170,
                                      height: 170,
                                      fit: BoxFit.cover, // 🔑 KEY LINE
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.grey.shade600,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: InkWell(
                              onTap: _pickProfileImage,
                              child: const CircleAvatar(
                                radius: 20, // slightly bigger edit icon
                                backgroundColor: Colors.white,
                                child: Icon(Icons.edit, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 30),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),

                            // EMAIL
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                email,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ✅ PROFILE COMPLETENESS (NEW LOCATION)
                            const Text(
                              'Profile completeness',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // PROFILE COMPLETENESS VALUE
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    value: profileCompletion / 100,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.green,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${profileCompletion.toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profileImageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        profileImageError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            /* ================= INFORMATION ================= */
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inlineEditableField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    focusNode: _fullNameFocus,
                    isEditing: editFullName,
                    onEdit: () {
                      _fullNameController.text = fullName; // ✅ ADD
                      setState(() {
                        editFullName = true;
                      });
                      _fullNameFocus.requestFocus();
                    },
                    onSave: () {
                      setState(() {
                        fullName = _fullNameController.text;
                        editFullName = false;
                      });
                      _validateProfile();
                      _calculateProfileCompletion();
                    },
                  ),

                  Row(
                    children: [
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          _phoneController.text = phone;
                          setState(() {
                            editPhone = true;
                          });

                          // 🔑 WAIT FOR REBUILD BEFORE REQUESTING FOCUS
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _phoneFocus.requestFocus();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // COUNTRY CODE DROPDOWN
                      Builder(
                        builder: (context) {
                          return GestureDetector(
                            // onTap: () {
                            //   _showCountryCodeMenu(context);
                            // },
                            child: Container(
                              width: 90,
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white, // ✅ WHITE (not grey)
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedCountryCode,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  // AnimatedSwitcher(
                                  //   duration: const Duration(milliseconds: 200),
                                  //   transitionBuilder: (child, animation) {
                                  //     return RotationTransition(
                                  //       turns: animation,
                                  //       child: child,
                                  //     );
                                  //   },
                                  //   child: Icon(
                                  //     isCountryMenuOpen
                                  //         ? Icons.keyboard_arrow_up
                                  //         : Icons.keyboard_arrow_down,
                                  //     key: ValueKey(isCountryMenuOpen),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      // PHONE NUMBER FIELD
                      Expanded(
                        child: editPhone
                            ? TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '10 digit number',
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                ),
                                onChanged: (v) {
                                  phone = v;
                                  _validateProfile();
                                },
                                onEditingComplete: () {
                                  _phoneFocus.unfocus();
                                },
                              )
                            : Container(
                                height: 48,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  phone.isEmpty ? '' : phone,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black, // ✅ ALWAYS BLACK
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),

                  if (phoneError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        phoneError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  _inlineEditableField(
                    label: 'Address',
                    controller: _addressController,
                    focusNode: _addressFocus,
                    isEditing: editAddress,
                    maxLines: null,
                    onEdit: () {
                      _addressController.text = address; // ✅ ADD
                      setState(() {
                        editAddress = true;
                      });
                      _addressFocus.requestFocus();
                    },
                    onSave: () {
                      setState(() {
                        address = _addressController.text;
                        editAddress = false;
                      });
                      _validateProfile();
                      _calculateProfileCompletion();
                    },
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
                    ),
                    onSubmitted: (v) {
                      if (v.isEmpty || !_onlyLetters(v)) return;

                      setState(() {
                        skills.insert(0, v);
                        _skillController.clear();
                      });
                      _validateProfile(); // ADD
                      _calculateProfileCompletion();
                    },
                  ),
                  const SizedBox(height: 16),
                  _chipList(skills, (i) => skills.removeAt(i)),
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
                    ),
                    onSubmitted: (v) {
                      if (v.isEmpty || !_onlyLetters(v)) return;
                      setState(() {
                        interests.insert(0, v);
                        _interestController.clear();
                        _validateProfile();
                        _calculateProfileCompletion();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _chipList(interests, (i) => interests.removeAt(i)),
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
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Certificates'),
                    onPressed: _pickCertificate,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(certificates.length, (i) {
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
                                    _validateProfile();
                                    _calculateProfileCompletion();
                                  },
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            /* ================= LOGOUT ================= */
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 240, 67, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {},
                  icon: const SizedBox(),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        FontAwesomeIcons.rightFromBracket,
                        size: 16,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

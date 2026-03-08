import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/manager_drawer.dart';
import '../core/theme.dart';
import '../../../services/supabase_service.dart';
import '../../../services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostEventsScreen extends StatefulWidget {
  final Map<String, dynamic>? editEvent;
  const PostEventsScreen({super.key, this.editEvent});

  @override
  State<PostEventsScreen> createState() => _PostEventsScreenState();
}

class _PostEventsScreenState extends State<PostEventsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _volunteersNeededController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roleDescriptionController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  final _dropdownMenuController = TextEditingController();
  
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  final _picker = ImagePicker();
  
  DateTime? _eventDateTime;
  DateTime? _registrationDeadline;
  
  List<String> _availableCategories = [];
  final List<String> _selectedCategories = [];
  String? _selectedCategoryDropdown;
  bool _showCustomCategoryInput = false;
  
  String _paymentType = 'Unpaid';
  bool _certificateProvided = false;
  bool _foodProvided = false;
  final List<String> _skillsRequired = [];
  final _skillController = TextEditingController();
  
  String _eventStatus = 'open'; // Default to open
  
  bool _isPosting = false;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32, // Padding left and right 16 each
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 56.0), // Shift it below the container
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: _availableCategories.map((cat) {
                  return InkWell(
                    onTap: () {
                      _closeDropdown();
                      setState(() {
                        _selectedCategoryDropdown = cat;
                        if (cat == 'Other') {
                          _showCustomCategoryInput = true;
                        } else if (cat != null) {
                          _showCustomCategoryInput = false;
                          if (!_selectedCategories.contains(cat)) {
                            _selectedCategories.insert(0, cat);
                          }
                          _selectedCategoryDropdown = null;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(cat, style: const TextStyle(fontSize: 16)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.editEvent != null) {
      _nameController.text = widget.editEvent!['name'] ?? widget.editEvent!['title'] ?? '';
      _locationController.text = widget.editEvent!['location'] ?? '';
      _volunteersNeededController.text = widget.editEvent!['volunteers_needed']?.toString() ?? '';
      _descriptionController.text = widget.editEvent!['description'] ?? '';
      
      if (widget.editEvent!['date'] != null) {
        _eventDateTime = DateTime.tryParse(widget.editEvent!['date']);
      } else if (widget.editEvent!['date_raw'] != null) {
        _eventDateTime = DateTime.tryParse(widget.editEvent!['date_raw']);
      }

      if (widget.editEvent!['registration_deadline'] != null) {
        _registrationDeadline = DateTime.tryParse(widget.editEvent!['registration_deadline']);
      }
      
      
      if (widget.editEvent!['categories'] != null) {
        _selectedCategories.addAll(List<String>.from(widget.editEvent!['categories']));
      } else if (widget.editEvent!['category'] != null) {
        _selectedCategories.add(widget.editEvent!['category'].toString());
      }
      
      _roleDescriptionController.text = widget.editEvent!['role_description'] ?? '';
      _paymentType = widget.editEvent!['payment_type'] ?? 'Unpaid';
      _paymentAmountController.text = widget.editEvent!['payment_amount'] ?? '';
      _certificateProvided = widget.editEvent!['certificate_provided'] == true;
      _foodProvided = widget.editEvent!['food_provided'] == true;
      
      final currentStatus = widget.editEvent!['status'];
      if (currentStatus == 'active') {
        _eventStatus = 'open';
      } else if (currentStatus == 'closed' || currentStatus == 'draft') {
        _eventStatus = currentStatus;
      }
      
      if (widget.editEvent!['skills_required'] != null) {
        _skillsRequired.addAll(List<String>.from(widget.editEvent!['skills_required']));
      }
    }
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    if (mounted) {
      setState(() {
        _availableCategories = cats;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _volunteersNeededController.dispose();
    _descriptionController.dispose();
    _roleDescriptionController.dispose();
    _paymentAmountController.dispose();
    _categoryController.dispose();
    _skillController.dispose();
    _dropdownMenuController.dispose();
    _closeDropdown();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context, bool isEventDate) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime.now();
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    if (isEventDate) {
      if (_registrationDeadline != null) {
        firstDate = _registrationDeadline!.add(const Duration(days: 4, hours: 23, minutes: 59));
      } else {
        firstDate = DateTime.now().add(const Duration(days: 4));
      }
      initialDate = firstDate.isAfter(initialDate) ? firstDate : initialDate;
    } else {
      if (_eventDateTime != null) {
        lastDate = _eventDateTime!.subtract(const Duration(days: 4));
      }
    }

    // Enforce bounds to prevent crashes
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;

    if (firstDate.isAfter(lastDate)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid date range. Ensure the event is at least 4 days after the deadline.')));
      }
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate == null) return;

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      final dateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute,
      );
      if (isEventDate) {
        _eventDateTime = dateTime;
      } else {
        _registrationDeadline = dateTime;
      }
    });
  }

  Future<void> _postEvent() async {
    if (_eventStatus != 'draft') {
      if (!_formKey.currentState!.validate()) return;
      if (_eventDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select event date and time')));
        return;
      }
    } else {
      // Basic validation for draft: At least need a name
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide an event name to save as draft')));
        return;
      }
    }

    setState(() => _isPosting = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String? imageUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        imageUrl = await SupabaseService.uploadEventImageBytes(
          _selectedImageBytes!, 
          _selectedImageName!, 
          user.id
        );
      }

      final dbStatus = _eventStatus == 'open' ? 'active' : _eventStatus;
      
      final eventData = {
        'name': _nameController.text,
        'image_url': imageUrl ?? widget.editEvent?['image_url'],
        'location': _locationController.text,
        'volunteers_needed': int.tryParse(_volunteersNeededController.text) ?? 1,
        'description': _descriptionController.text,
        'role_description': _roleDescriptionController.text,
        'payment_type': _paymentType,
        'payment_amount': _paymentType == 'Paid' ? _paymentAmountController.text : null,
        'certificate_provided': _certificateProvided,
        'food_provided': _foodProvided,
        'skills_required': _skillsRequired,
        'categories': _selectedCategories,
        'registration_deadline': _registrationDeadline?.toIso8601String(),
        'date': _eventDateTime?.toIso8601String(),
        'user_id': user.id,
        'status': dbStatus,
        'current_volunteers_count': widget.editEvent?['current_volunteers_count'] ?? 0,
      };

      if (widget.editEvent != null) {
        await SupabaseService.client
            .from('events')
            .update(eventData)
            .eq('id', widget.editEvent!['id']);
      } else {
        await SupabaseService.client.from('events').insert(eventData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editEvent != null ? 'Event updated successfully!' : 'Event posted successfully!')),
      );
      
      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _locationController.clear();
      _volunteersNeededController.clear();
      _descriptionController.clear();
      _roleDescriptionController.clear();
      _paymentAmountController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
        _eventDateTime = null;
        _registrationDeadline = null;
        _selectedCategories.clear();
        _skillsRequired.clear();
        _paymentType = 'Unpaid';
        _certificateProvided = false;
        _foodProvided = false;
        _eventStatus = 'open';
      });

      // Redirect to My Events page
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/manager-my-events');
        }
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editEvent != null ? 'Edit Event' : 'Post Events'),
      ),
      drawer: const ManagerDrawer(currentRoute: '/manager-post-events'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Event Image'),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Click to select event image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Event Details'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Name of the event', Icons.event),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Event location', Icons.location_on),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _volunteersNeededController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of volunteers needed (Max 50)',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter number of volunteers needed';
                  final num = int.tryParse(value);
                  if (num == null) return 'Please enter a valid number';
                  if (num <= 0) return 'Must need at least 1 volunteer';
                  if (num > 50) return 'Cannot exceed 50 volunteers';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(_roleDescriptionController, 'Role Description', Icons.work_outline, maxLines: 2),
              const SizedBox(height: 16),
              
              _buildSectionTitle('Payment & Benefits'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Unpaid'),
                      value: 'Unpaid',
                      groupValue: _paymentType,
                      onChanged: (value) => setState(() => _paymentType = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Paid'),
                      value: 'Paid',
                      groupValue: _paymentType,
                      onChanged: (value) => setState(() => _paymentType = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              if (_paymentType == 'Paid') ...[
                const SizedBox(height: 8),
                _buildTextField(_paymentAmountController, 'Payment Amount (e.g. ₹500/day)', Icons.currency_rupee),
              ],
              
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Certificate Provided'),
                value: _certificateProvided,
                onChanged: (val) => setState(() => _certificateProvided = val),
              ),
              SwitchListTile(
                title: const Text('Food Provided'),
                value: _foodProvided,
                onChanged: (val) => setState(() => _foodProvided = val),
              ),
              
              const SizedBox(height: 16),
              _buildSectionTitle('Event description'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Event description', Icons.description, maxLines: 3),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Skills Required'),
              const SizedBox(height: 8),
              _buildSkillInput(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _skillsRequired.map((skill) {
                  return Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _skillsRequired.remove(skill);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Date & Deadline'),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_eventDateTime == null ? 'Select Event Date & Time' : 'Event: ${_eventDateTime.toString()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(context, true),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_registrationDeadline == null ? 'Select Registration Deadline' : 'Deadline: ${_registrationDeadline.toString()}'),
                trailing: const Icon(Icons.timer_outlined),
                onTap: () => _pickDateTime(context, false),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Categories'),
              const SizedBox(height: 8),
              CompositedTransformTarget(
                link: _layerLink,
                child: GestureDetector(
                  onTap: _toggleDropdown,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black54),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategoryDropdown ?? 'Select a category to add',
                          style: TextStyle(
                            color: _selectedCategoryDropdown == null ? Colors.grey[600] : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Icon(_isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showCustomCategoryInput) ...[
                const SizedBox(height: 12),
                _buildCategoryInput(),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedCategories.map((cat) {
                  return Chip(
                    label: Text(cat),
                    onDeleted: () {
                      setState(() {
                        _selectedCategories.remove(cat);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppColors.mintIce,
                    labelStyle: const TextStyle(color: AppColors.hunterGreen),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Application Status Control'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _eventStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.settings_suggest),
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open (Visible to Volunteers)')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed (Hidden from Volunteers)')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft (Save to resume later)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _eventStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _postEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.midnightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(widget.editEvent != null ? 'Update Event' : 'Save Event', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  final _categoryController = TextEditingController();

  Widget _buildCategoryInput() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(
        labelText: 'Add category and press Enter',
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addCategory,
        ),
      ),
      onFieldSubmitted: (_) => _addCategory(),
    );
  }

  void _addCategory() {
    final text = _categoryController.text.trim();
    if (text.isNotEmpty && !_selectedCategories.contains(text)) {
      setState(() {
        _selectedCategories.insert(0, text); // Add to top
        _categoryController.clear();
        _showCustomCategoryInput = false;
        _dropdownMenuController.clear();
        _selectedCategoryDropdown = null; // reset to allow continuous selection
      });
    }
  }

  Widget _buildSkillInput() {
    return TextFormField(
      controller: _skillController,
      decoration: InputDecoration(
        labelText: 'Add skill and press Enter',
        prefixIcon: const Icon(Icons.star_border),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addSkill,
        ),
      ),
      onFieldSubmitted: (_) => _addSkill(),
    );
  }

  void _addSkill() {
    final text = _skillController.text.trim();
    if (text.isNotEmpty && !_skillsRequired.contains(text)) {
      setState(() {
        _skillsRequired.add(text);
        _skillController.clear();
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.midnightBlue),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}
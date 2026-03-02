import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/manager_drawer.dart';
import '../core/theme.dart';
import '../../../services/supabase_service.dart';
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
  
  File? _selectedImage;
  final _picker = ImagePicker();
  
  DateTime? _eventDateTime;
  DateTime? _registrationDeadline;
  
  final List<String> _availableCategories = [
    'Wedding', 'Party', 'Corporate', 'Festival', 'Concert', 'Workshop', 'Charity', 'Sports', 'Other'
  ];
  final List<String> _selectedCategories = [];

  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _volunteersNeededController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context, bool isEventDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (!_formKey.currentState!.validate()) return;
    if (_eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select event date and time')));
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await SupabaseService.uploadEventImage(_selectedImage!, user.id);
      }

      final eventData = {
        'name': _nameController.text,
        'image_url': imageUrl ?? widget.editEvent?['image_url'],
        'location': _locationController.text,
        'volunteers_needed': int.parse(_volunteersNeededController.text),
        'description': _descriptionController.text,
        'categories': _selectedCategories,
        'registration_deadline': _registrationDeadline?.toIso8601String(),
        'date': _eventDateTime?.toIso8601String(),
        'user_id': user.id,
        'status': 'active',
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
      setState(() {
        _selectedImage = null;
        _eventDateTime = null;
        _registrationDeadline = null;
        _selectedCategories.clear();
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
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
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
              _buildTextField(_volunteersNeededController, 'Number of volunteers needed', Icons.people, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Event description', Icons.description, maxLines: 3),
              
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
              _buildCategoryInput(),
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
              if (_availableCategories.any((cat) => !_selectedCategories.contains(cat))) ...[
                const SizedBox(height: 16),
                const Text('Suggested:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableCategories
                      .where((cat) => !_selectedCategories.contains(cat))
                      .map((cat) {
                    return ActionChip(
                      label: Text(cat),
                      onPressed: () {
                        setState(() {
                          _selectedCategories.insert(0, cat);
                        });
                      },
                      backgroundColor: Colors.grey[100],
                    );
                  }).toList(),
                ),
              ],

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
                    : Text(widget.editEvent != null ? 'Update Event' : 'Post & Send', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

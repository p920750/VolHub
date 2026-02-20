import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import '../../services/host_service.dart';

class PostEventPage extends StatefulWidget {
  const PostEventPage({super.key});

  @override
  State<PostEventPage> createState() => _PostEventPageState();
}

class _PostEventPageState extends State<PostEventPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final _picker = ImagePicker();
  
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _reqsController = TextEditingController();
  final _detailsController = TextEditingController();

  DateTime? _selectedDate;
  String _hostName = 'Host';
  bool _isFetchingProfile = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'Wedding',
    'Party',
    'Emergency Supplies',
    'Catering',
    'Festival',
    'Photography',
    'Corporate Event',
    'Concert',
    'Workshop',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadHostProfile();
  }

  Future<void> _loadHostProfile() async {
    try {
      final userData = await SupabaseService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _hostName = userData['full_name'] ?? _hostName;
          _isFetchingProfile = false;
        });
      } else if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _budgetController.dispose();
    _reqsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a New Event',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isFetchingProfile 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Post a New Event',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001529),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '✨',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reach out to top event managers for your upcoming occasion.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Event Title
                  _buildTextField(
                    controller: _titleController,
                    label: 'Event Title',
                    placeholder: 'e.g. Summer Music Festival 2026',
                  ),
                  const SizedBox(height: 20),

                  // Event Category
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF001529),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          hintText: 'Select Category',
                          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF001529), width: 1.5),
                          ),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    placeholder: 'e.g. Central Park, NY',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _dateController,
                          label: 'Date',
                          placeholder: 'mm/dd/yyyy',
                          icon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                            );
                            if (date != null) {
                              _selectedDate = date;
                              _dateController.text = "${date.month}/${date.day}/${date.year}";
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _timeController,
                          label: 'Time',
                          placeholder: '--:-- --',
                          icon: Icons.access_time,
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              _timeController.text = time.format(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Budget/Payment Amount
                  _buildTextField(
                    controller: _budgetController,
                    label: 'Budget / Payment Amount',
                    placeholder: 'e.g. \$500 - \$1000',
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Specific Requirements
                  _buildTextField(
                    controller: _reqsController,
                    label: 'Specific Requirements',
                    placeholder: 'e.g. Needs 5+ years experience...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  
                  // Event Details
                  _buildTextField(
                    controller: _detailsController,
                    label: 'Event Details',
                    placeholder: 'Describe your event in detail...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  // Cover Image Upload
                  const Text(
                    'Cover Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001529),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.withOpacity(0.02),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
                                const SizedBox(height: 12),
                                const Text(
                                  'Click to upload or drag and drop',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF001529),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PNG, JPG up to 10MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Post Event Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (_titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter an event title')),
                            );
                            return;
                          }

                          try {
                            final String? imagePath = _image?.path;
                            
                            await HostService.addEvent({
                              'title': _titleController.text,
                              'date_raw': _selectedDate?.toIso8601String(),
                              'time': _timeController.text,
                              'location': _locationController.text.isEmpty ? 'Online' : _locationController.text,
                              'budget': _budgetController.text,
                              'requirements': _reqsController.text,
                              'description': _detailsController.text,
                              'imageUrl': imagePath,
                              'host_name': _hostName,
                              'category': _selectedCategory,
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event Posted Successfully!')),
                              );
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to post event: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001529),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Post Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // Extra space at bottom for scrolling
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required String placeholder,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF001529),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF001529), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

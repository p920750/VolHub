import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import '../../services/host_service.dart';
import '../../services/category_service.dart';

class EditEventPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _existingImageUrls = [];
  List<XFile> _newImages = [];
  final _picker = ImagePicker();
  
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _deadlineDateController;
  late TextEditingController _deadlineTimeController;
  late TextEditingController _budgetController;
  late TextEditingController _reqsController;
  late TextEditingController _detailsController;
  late TextEditingController _categoryController;

  DateTime? _selectedDate;
  DateTime? _selectedDeadlineDate;
  TimeOfDay? _selectedDeadlineTime;
  bool _isSaving = false;

  List<String> _categories = [];
  String? _selectedCategory;
  bool _showCustomCategoryInput = false;

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
        width: size.width - 48, // 24 padding on left and right
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 56.0),
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
                children: _categories.map((cat) {
                  return InkWell(
                    onTap: () {
                      _closeDropdown();
                      setState(() {
                        _selectedCategory = cat;
                        _showCustomCategoryInput = (cat == 'Other');
                        if (cat != 'Other' && cat != null) {
                          _categoryController.text = cat;
                        } else if (cat == 'Other' && widget.event['category'] != null && !_categories.contains(widget.event['category'])) {
                          _categoryController.text = widget.event['category'];
                        } else {
                          _categoryController.clear();
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
    _titleController = TextEditingController(text: widget.event['title']);
    _locationController = TextEditingController(text: widget.event['location']);
    _budgetController = TextEditingController(text: widget.event['budget']);
    _reqsController = TextEditingController(text: widget.event['requirements']);
    _detailsController = TextEditingController(text: widget.event['description']);
    _categoryController = TextEditingController(text: widget.event['category']);
    _loadCategories();
    // Attempt to parse existing date if possible
    String formattedDate = '';
    String timeStr = widget.event['time'] ?? '';
    if (widget.event['date_raw'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.event['date_raw']);
        formattedDate = "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
      } catch (_) {}
    }
    
    _dateController = TextEditingController(text: formattedDate.isEmpty ? widget.event['date'] : formattedDate);
    _timeController = TextEditingController(text: timeStr);

    // Parse existing registration_deadline
    String formattedDeadlineDate = '';
    String formattedDeadlineTime = '';
    if (widget.event['registration_deadline'] != null && widget.event['registration_deadline'].toString().isNotEmpty) {
      try {
        final DateTime parsedDeadline = DateTime.parse(widget.event['registration_deadline']);
        _selectedDeadlineDate = parsedDeadline;
        _selectedDeadlineTime = TimeOfDay.fromDateTime(parsedDeadline);
        formattedDeadlineDate = "${parsedDeadline.day.toString().padLeft(2, '0')}/${parsedDeadline.month.toString().padLeft(2, '0')}/${parsedDeadline.year}";
        
        final hour24 = parsedDeadline.hour;
        final minute = parsedDeadline.minute.toString().padLeft(2, '0');
        final ampm = hour24 >= 12 ? 'pm' : 'am';
        final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
        final hourStr = hour12.toString().padLeft(2, '0');
        formattedDeadlineTime = "$hourStr:$minute $ampm";
      } catch (_) {}
    }

    _deadlineDateController = TextEditingController(text: formattedDeadlineDate);
    _deadlineTimeController = TextEditingController(text: formattedDeadlineTime);

    if (widget.event['image_url'] != null && widget.event['image_url'].toString().isNotEmpty) {
      _existingImageUrls = widget.event['image_url'].toString().split(',').map((s) => s.trim()).toList();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        final existingCat = widget.event['category']?.toString();
        if (existingCat != null && existingCat.isNotEmpty) {
          if (_categories.contains(existingCat)) {
            _selectedCategory = existingCat;
            _showCustomCategoryInput = (existingCat == 'Other');
          } else {
            // It's a custom one not currently in the db list somehow, or 'Other' with manual input
            _selectedCategory = 'Other';
            _showCustomCategoryInput = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _deadlineDateController.dispose();
    _deadlineTimeController.dispose();
    _budgetController.dispose();
    _reqsController.dispose();
    _detailsController.dispose();
    _categoryController.dispose();
    _closeDropdown();
    super.dispose();
  }

  Future<void> _pickDateInSequence() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => const _CustomDatePickerDialog(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  Future<void> _pickDeadlineDateInSequence() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => const _CustomDatePickerDialog(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDeadlineDate = pickedDate;
        _deadlineDateController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles);
      });
      _formKey.currentState?.validate();
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
          'Edit Event Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                children: [
                  const Text(
                    'Update Request',
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
                'Update the requirements for the conducting Manager.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _titleController,
                label: 'Event Title',
                placeholder: 'e.g. Summer Music Festival 2026',
              ),
              const SizedBox(height: 20),

              const Text('Event Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001529))),
              const SizedBox(height: 8),
              FormField<String>(
                initialValue: _selectedCategory,
                validator: (value) {
                  if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: GestureDetector(
                          onTap: _toggleDropdown,
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: field.hasError ? Colors.red : Colors.grey.withOpacity(0.3),
                                width: field.hasError ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCategory ?? 'Select a category',
                                  style: TextStyle(
                                    color: _selectedCategory == null ? Colors.grey[600] : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(_isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 4),
                        Text(field.errorText ?? 'Please select a category', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  );
                },
              ),
              if (_showCustomCategoryInput) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _categoryController,
                  label: 'Custom Category',
                  placeholder: 'Type your custom category...',
                ),
              ],
              const SizedBox(height: 20),

              _buildTextField(
                controller: _locationController,
                label: 'Location',
                placeholder: 'e.g. Central Park, NY',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dateController,
                      label: 'Event Date',
                      placeholder: 'dd/mm/yyyy',
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _pickDateInSequence,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _timeController,
                      label: 'Event Time',
                      placeholder: 'hh:mm am/pm',
                      icon: Icons.access_time,
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && context.mounted) {
                          _timeController.text = time.format(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _deadlineDateController,
                      label: 'Deadline Date',
                      placeholder: 'dd/mm/yyyy',
                      icon: Icons.event_available_outlined,
                      readOnly: true,
                      onTap: _pickDeadlineDateInSequence,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _deadlineTimeController,
                      label: 'Deadline Time',
                      placeholder: 'hh:mm am/pm',
                      icon: Icons.timer_outlined,
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && context.mounted) {
                          _selectedDeadlineTime = time;
                          _deadlineTimeController.text = time.format(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _budgetController,
                label: 'Budget / Payment Amount',
                placeholder: 'e.g. \$500 - \$1000',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _detailsController,
                label: 'Event Description',
                placeholder: 'Describe your event in detail...',
                maxLines: 6,
                isScrollable: true,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _reqsController,
                label: 'Company Requirements',
                placeholder: 'e.g. Needs 5+ years experience...',
                maxLines: 6,
                isScrollable: true,
              ),
              const SizedBox(height: 24),

              // Image Management
              _buildImageManager(),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001529),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Images',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF001529),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.02),
          ),
          child: (_existingImageUrls.isEmpty && _newImages.isEmpty)
              ? GestureDetector(
                  onTap: _pickImage,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
                      SizedBox(height: 12),
                      Text('Add location images', style: TextStyle(color: Color(0xFF001529))),
                    ],
                  ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: [
                    ..._existingImageUrls.map((url) => _buildImageThumbnail(url, isUrl: true)),
                    ..._newImages.map((xFile) => _buildImageThumbnail(xFile, isUrl: false)),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 32),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(dynamic content, {required bool isUrl}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isUrl
                  ? Image.network(content, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                  : (kIsWeb 
                      ? Image.network((content as XFile).path, fit: BoxFit.cover)
                      : Image.file(File((content as XFile).path), fit: BoxFit.cover)),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isUrl) {
                    _existingImageUrls.remove(content);
                  } else {
                    _newImages.remove(content);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
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
    bool isScrollable = false,
  }) {
    return FormField<String>(
      validator: (value) {
        if (controller?.text.trim().isEmpty ?? true) {
          return 'This field is required';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001529))),
              ],
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(field.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 8),
            Container(
              height: isScrollable ? 120 : null,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                maxLines: isScrollable ? null : maxLines,
                keyboardType: maxLines > 1 || isScrollable ? TextInputType.multiline : TextInputType.text,
                onChanged: (val) => field.didChange(val),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  errorText: field.hasError ? '' : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF001529), width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');

        // 1. Upload new images to Supabase Storage
        final List<String> uploadedUrls = [];
        for (final xFile in _newImages) {
          final bytes = await xFile.readAsBytes();
          final url = await SupabaseService.uploadEventImageBytes(
            bytes,
            xFile.name,
            userId,
          );
          if (url != null) {
            uploadedUrls.add(url);
          }
        }

        // 2. Combine existing and newly uploaded URLs
        // FILTER: Exclude any remaining blob: URLs that might have leaked into existing urls
        final List<String> filteredExisting = _existingImageUrls
            .where((url) => url is String && !url.toString().startsWith('blob:'))
            .cast<String>()
            .toList();

        final List<String> allImages = [
          ...filteredExisting,
          ...uploadedUrls,
        ];

        final String timeValue = _timeController.text.trim();
        
        DateTime? combinedDeadline;
        if (_selectedDeadlineDate != null) {
          combinedDeadline = DateTime(
            _selectedDeadlineDate!.year,
            _selectedDeadlineDate!.month,
            _selectedDeadlineDate!.day,
            _selectedDeadlineTime?.hour ?? 23,
            _selectedDeadlineTime?.minute ?? 59,
          );
        }

        final Map<String, dynamic> updates = {
          'title': _titleController.text,
          'location': _locationController.text,
          'date': _selectedDate?.toIso8601String() ?? (widget.event['date_raw'] == 'TBD' ? null : widget.event['date_raw']),
          'registration_deadline': combinedDeadline?.toIso8601String(),
          'budget': _budgetController.text,
          'requirements': _reqsController.text,
          'description': _detailsController.text,
          'category': _categoryController.text,
          'time': (timeValue == 'TBD' || timeValue.isEmpty) ? null : timeValue,
          'image_url': allImages.join(','),
        };

        await HostService.updateEvent(widget.event['id'].toString(), updates);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update event: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}

// Inherited from PostEventPage for consistency
class _CustomDatePickerDialog extends StatefulWidget {
  const _CustomDatePickerDialog();

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  int _view = 0; // 0: Year, 1: Month, 2: Day
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  final DateTime _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 160,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF001529),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Selected Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(_getFormattedPreview(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_view > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _view--),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                      label: const Text('Back', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Expanded(child: _buildPicker()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedPreview() {
    final List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    String day = _selectedDay?.toString() ?? _now.day.toString();
    String month = _selectedMonth != null ? months[_selectedMonth! - 1] : months[_now.month - 1];
    String year = _selectedYear?.toString() ?? _now.year.toString();
    return '$day\n$month\n$year';
  }

  String _getTitle() {
    switch (_view) {
      case 0: return 'Select Year';
      case 1: return 'Select Month';
      case 2: return 'Select Date';
      default: return '';
    }
  }

  Widget _buildPicker() {
    switch (_view) {
      case 0: return _buildYearPicker();
      case 1: return _buildMonthPicker();
      case 2: return _buildDayPicker();
      default: return Container();
    }
  }

  Widget _buildYearPicker() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.8, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: 31,
      itemBuilder: (context, index) {
        final year = _now.year + index;
        return _buildSelectableBox(
          text: year.toString(),
          isSelected: _selectedYear == year,
          onTap: () => setState(() { _selectedYear = year; _view = 1; }),
        );
      },
    );
  }

  Widget _buildMonthPicker() {
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.8, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final bool isPast = _selectedYear == _now.year && month < _now.month;
        return _buildSelectableBox(
          text: months[index],
          isSelected: _selectedMonth == month,
          isEnabled: !isPast,
          onTap: () => setState(() { _selectedMonth = month; _view = 2; }),
        );
      },
    );
  }

  Widget _buildDayPicker() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear!, _selectedMonth!);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final bool isPast = _selectedYear == _now.year && _selectedMonth == _now.month && day < _now.day;
        return _buildSelectableBox(
          text: day.toString(),
          isSelected: _selectedDay == day,
          isEnabled: !isPast,
          onTap: () => Navigator.pop(context, DateTime(_selectedYear!, _selectedMonth!, day)),
        );
      },
    );
  }

  Widget _buildSelectableBox({required String text, required VoidCallback onTap, bool isSelected = false, bool isEnabled = true}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF001529) : (isEnabled ? const Color(0xFF001529).withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : (isEnabled ? Colors.black : Colors.grey), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

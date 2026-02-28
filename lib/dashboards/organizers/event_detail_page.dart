import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../services/host_service.dart';
import 'edit_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> _currentEvent;
  bool _isLoading = false;
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoadingApplicants = true;
  Map<String, dynamic>? _managerInfo;
  bool _isLoadingManagerInfo = false;
  bool _isEditMode = false; // Added this line

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadEventData();
    _loadApplicants();
    _checkAndLoadManagerInfo();
  }

  void _checkAndLoadManagerInfo() {
    final List<dynamic>? managerIds = _currentEvent['manager_ids'];
    if (managerIds != null && managerIds.isNotEmpty && _currentEvent['status'] == 'accepted') {
      _loadManagerInfo(managerIds.first.toString());
    }
  }

  Future<void> _loadManagerInfo(String managerId) async {
    setState(() => _isLoadingManagerInfo = true);
    try {
      final info = await HostService.getManagerDetails(managerId);
      if (mounted) {
        setState(() {
          _managerInfo = info;
          _isLoadingManagerInfo = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingManagerInfo = false);
    }
  }

  Future<void> _loadApplicants() async {
    if (_currentEvent['id'] == null) return;
    setState(() => _isLoadingApplicants = true);
    try {
      final applicants = await HostService.getEventApplications(_currentEvent['id'].toString());
      if (mounted) {
        setState(() {
          _applicants = applicants;
          _isLoadingApplicants = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingApplicants = false);
    }
  }

  Future<void> _loadEventData() async {
    if (_currentEvent['id'] == null) return;
    
    setState(() => _isLoading = true);
    try {
      // In a real app, we'd have a getEventById method. 
      // For now, we can fetch all and filter, or add a method to HostService.
      // HostService.getEvents() returns everything for this host.
      final events = await HostService.getEvents();
      final updatedEvent = events.firstWhere(
        (e) => e['id'].toString() == _currentEvent['id'].toString(),
        orElse: () => _currentEvent,
      );
      
      if (mounted) {
        setState(() {
          _currentEvent = updatedEvent;
          _isLoading = false;
        });
        _checkAndLoadManagerInfo();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _currentEvent['title'] ?? 'Event Details';
    final String category = _currentEvent['category'] ?? 'Other';
    final String dateTime = _currentEvent['date_time_formatted'] ?? 'N/A';
    final String location = _currentEvent['location'] ?? 'N/A';
    final String budget = _currentEvent['budget'] ?? 'N/A';
    final String requirements = _currentEvent['requirements'] ?? 'No specific requirements listed.';
    final String description = _currentEvent['description'] ?? 'No description provided.';
    final String imageUrls = _currentEvent['image_url'] ?? '';
    final String status = _currentEvent['status'] ?? 'Pending';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context, true),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Date & Time', dateTime),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person_outline, 'Posted By', _currentEvent['host_name'] ?? 'Host'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.category_outlined, 'Category', category),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.account_balance_wallet_outlined, 'Budget', budget),
                  const Divider(height: 48),
                  const Text(
                    'Event Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpandableText(text: description),
                  if (status == 'rejected' && _currentEvent['rejection_reason'] != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Rejection Reason',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentEvent['rejection_reason'],
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (status == 'accepted' || status == 'active') ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Assigned Manager',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingManagerInfo 
                      ? const Center(child: CircularProgressIndicator())
                      : _managerInfo == null
                        ? const Text('Loading manager info...')
                        : Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Colors.grey[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(_managerInfo!['profile_photo'] ?? 'https://i.pravatar.cc/150?u=manager'),
                                    ),
                                    title: Text(
                                      _managerInfo!['full_name'] ?? 'Manager',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    subtitle: Text(
                                      '${_managerInfo!['company_name'] ?? 'Independent'} • ${_managerInfo!['company_location'] ?? 'Location N/A'}',
                                    ),
                                  ),
                                  if (_managerInfo!['bio'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _managerInfo!['bio'],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Divider(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildManagerContactItem(Icons.email_outlined, 'Email'),
                                      _buildManagerContactItem(Icons.phone_outlined, 'Call'),
                                      _buildManagerContactItem(Icons.person_pin_outlined, 'Profile'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                  const SizedBox(height: 32),
                  _ExpandableText(text: requirements),
                  if (imageUrls.isNotEmpty && imageUrls != 'null' && !imageUrls.contains('blob:')) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Location Images',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHorizontalImageGallery(imageUrls),
                  ],
                  const SizedBox(height: 40),
                  const Text(
                    'Interested Managers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingApplicants 
                    ? const Center(child: CircularProgressIndicator())
                    : _applicants.isEmpty
                      ? const Text('No managers have accepted yet.', style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _applicants.length,
                          itemBuilder: (context, index) {
                            final application = _applicants[index];
                            final manager = application['users'];
                            final List<dynamic> managerIds = _currentEvent['manager_ids'] ?? [];
                            final isConfirmed = managerIds.contains(manager['id']);
                            final String managerEmail = manager['email'] ?? 'No email';
                            final String managerCompany = manager['company_name'] ?? 'Independent';
                            final String managerLocation = manager['company_location'] ?? 'Location N/A';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(manager['profile_photo'] ?? 'https://i.pravatar.cc/150?u=${manager['id']}'),
                                      ),
                                      title: Text(manager['full_name'] ?? 'Unknown Manager', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$managerCompany • $managerLocation'),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(managerEmail, style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: isConfirmed 
                                        ? const Chip(label: Text('Confirmed'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white))
                                        : (false // You might want to allow multiple managers now
                                            ? null // Don't show confirm button if someone else is confirmed
                                            : ElevatedButton(
                                                onPressed: () async {
                                                  try {
                                                    await HostService.confirmManager(_currentEvent['id'].toString(), manager['id']);
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Manager confirmed!')),
                                                      );
                                                      _loadEventData();
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Failed to confirm: $e')),
                                                      );
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1E4D40), 
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                ),
                                                child: const Text('Confirm'),
                                              )),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context, 
                                                '/manager-profile-public',
                                                arguments: {'managerId': manager['id']},
                                              );
                                            },
                                            icon: const Icon(Icons.person_outline, size: 16),
                                            label: const Text('View Profile', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ListTile(
                                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF1E4D40)),
                                  title: const Text(
                                    'Edit Event Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF001529),
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditEventPage(event: _currentEvent),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadEventData();
                                    }
                                  },
                                ),
                                if (_isEditMode)
                                ListTile(
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  title: const Text(
                                    'Done Editing',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _isEditMode = false;
                                    });
                                    _loadEventData();
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                                  title: const Text(
                                    'Delete Event Permanent',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirmation(context);
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4D40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Manage Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to permanently delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (_currentEvent['id'] != null) {
                  await HostService.deleteEvent(_currentEvent['id'].toString());
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Go back to dashboard with refresh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted successfully')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete event: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerContactItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1E4D40), size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalImageGallery(String? urls) {
    if (urls == null || urls.trim().isEmpty || urls == 'null' || urls.contains('blob:')) {
      return const SizedBox.shrink();
    }
    
    final List<String> urlList = urls.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'null').toList();
    if (urlList.isEmpty) return const SizedBox.shrink();
    // User requested "right to left", which means we reverse the list or use reverse: true
    final List<String> displayedUrls = urlList.reversed.toList();
    
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayedUrls.length,
        itemBuilder: (context, index) {
          final url = displayedUrls[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showEnlargedImage(url),
                  child: Container(
                    width: 270,
                    height: 168,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildGalleryImage(url),
                    ),
                  ),
                ),
                if (_isEditMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _deleteImage(url),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalleryImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover);
    } else {
      if (kIsWeb) {
        return Image.network(url, fit: BoxFit.cover);
      }
      return Image.file(File(url), fit: BoxFit.cover);
    }
  }

  void _showEnlargedImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: InteractiveViewer(
                    child: _buildGalleryImage(url),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteImage(String urlToDelete) async {
    final String currentUrls = _currentEvent['image_url'] ?? '';
    final List<String> urlList = currentUrls.split(',').map((s) => s.trim()).toList();
    
    urlList.remove(urlToDelete);
    final String updatedUrls = urlList.join(',');
    
    try {
      await HostService.updateEventImages(_currentEvent['id'].toString(), updatedUrls);
      setState(() {
        _currentEvent['image_url'] = updatedUrls;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
    }
  }

  Widget _buildMultiImageWidget(String? urls) {
    return Container(); // No longer used in app bar, but keeping to avoid breaking references if any
  }

  Widget _buildSingleImageWidget(String url) {
    return Container(); // No longer used
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const Text('N/A');

    final lines = widget.text.split('\n');
    bool shouldShowReadMore = false;
    
    // Logic: contents more than 10 lines 
    // OR in 10th line more than 20 characters
    if (lines.length > 10) {
      shouldShowReadMore = true;
    } else if (lines.length == 10 && lines[9].length > 20) {
      shouldShowReadMore = true;
    }

    if (_isExpanded || !shouldShowReadMore) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          height: 1.6,
        ),
      );
    }

    // Truncate to 10 lines, and the 10th line to 20 characters
    String truncatedText = '';
    for (int i = 0; i < 9; i++) {
       truncatedText += '${lines[i]}\n';
    }
    String tenthLine = lines[9];
    if (tenthLine.length > 20) {
      tenthLine = '${tenthLine.substring(0, 20)}... ';
    } else {
      tenthLine = '$tenthLine... ';
    }
    truncatedText += tenthLine;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          height: 1.6,
        ),
        children: [
          TextSpan(text: truncatedText),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: const Text(
                'Read more',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

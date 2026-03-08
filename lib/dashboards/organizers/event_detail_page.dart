import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../services/host_service.dart';
import 'edit_event_page.dart';
import '../../../widgets/safe_avatar.dart';

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
  String? _expandedFieldId;

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

  Future<void> _handleAcceptManager(String managerId) async {
    try {
      await HostService.acceptManager(_currentEvent['id'].toString(), managerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager successfully assigned!')),
        );
        _loadEventData(); // Reload to reflect changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign manager: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectManager(String managerId) async {
    final String? deadlineStr = _currentEvent['registration_deadline'];
    int? daysLeft;
    if (deadlineStr != null) {
      try {
        final deadline = DateTime.parse(deadlineStr);
        daysLeft = deadline.difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    if (daysLeft != null && daysLeft == 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reject the accepted manager since only 5 days left for deadline')),
        );
      }
      return;
    }

    if (daysLeft != null && daysLeft < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reject the manager. Deadline is too close.')),
        );
      }
      return;
    }

    final TextEditingController reasonController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this manager. They will be notified.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await HostService.rejectManager(_currentEvent['id'].toString(), managerId, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager rejected successfully.')),
        );
        _loadEventData(); // Reload to reflect changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject manager: $e')),
        );
      }
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
    final String status = _getDynamicStatus(_currentEvent);
    final String eventId = _currentEvent['id']?.toString() ?? 'unknown';

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
                  _buildInfoRow(Icons.location_on_outlined, 'Event Location', location),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Event Date', dateTime),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.timer_outlined, 'Deadline for Acceptance', _currentEvent['registration_deadline_formatted'] ?? 'Not set'),
                  Builder(
                    builder: (context) {
                      if (status == 'Acceptance started') {
                         int daysLeft = 999;
                         if (_currentEvent['registration_deadline'] != null) {
                           try {
                             daysLeft = DateTime.parse(_currentEvent['registration_deadline']).difference(DateTime.now()).inDays;
                           } catch (_) {}
                         }
                         if (daysLeft <= 5) {
                           return Padding(
                             padding: const EdgeInsets.only(top: 12.0),
                             child: Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.all(8),
                                   decoration: BoxDecoration(
                                     color: Colors.orange[50],
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                                 ),
                                 const SizedBox(width: 16),
                                 const Text('Please accept a manager', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                               ],
                             ),
                           );
                         }
                      }
                      return const SizedBox.shrink();
                    }
                  ),
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
                  _ExpandableText(
                    text: description,
                    isExpanded: _expandedFieldId == '${eventId}_description',
                    onToggle: () {
                      setState(() {
                        if (_expandedFieldId == '${eventId}_description') {
                          _expandedFieldId = null;
                        } else {
                          _expandedFieldId = '${eventId}_description';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Company Requirements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpandableText(
                    text: requirements,
                    isExpanded: _expandedFieldId == '${eventId}_requirements',
                    onToggle: () {
                      setState(() {
                        if (_expandedFieldId == '${eventId}_requirements') {
                          _expandedFieldId = null;
                        } else {
                          _expandedFieldId = '${eventId}_requirements';
                        }
                      });
                    },
                  ),
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
                                    leading: SafeAvatar(
                                      radius: 30,
                                      imageUrl: _managerInfo!['profile_photo'] ?? 'https://i.pravatar.cc/150?u=manager',
                                      name: _managerInfo!['full_name'] ?? 'Manager',
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
                                      leading: SafeAvatar(
                                        imageUrl: manager['profile_photo'] ?? 'https://i.pravatar.cc/150?u=${manager['id']}',
                                        name: manager['full_name'] ?? 'Manager',
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                          const Spacer(),
                                            if (_currentEvent['assigned_manager_id'] == manager['id']) ...[
                                              const Text('Accepted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 12),
                                              Builder(
                                                builder: (context) {
                                                  int? daysLeft;
                                                  if (_currentEvent['registration_deadline'] != null) {
                                                    try {
                                                      daysLeft = DateTime.parse(_currentEvent['registration_deadline']).difference(DateTime.now()).inDays;
                                                    } catch (_) {}
                                                  }
                                                  if (daysLeft == null || daysLeft >= 5) {
                                                    return ElevatedButton(
                                                      onPressed: () => _handleRejectManager(manager['id']),
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0),
                                                      child: const Text('Reject'),
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                }
                                              ),
                                            ] else ...[
                                            Builder(
                                              builder: (context) {
                                                final rejectionReasonStr = _currentEvent['rejection_reason'] as String?;
                                                bool isOrganizerRejected = false;
                                                bool isManagerRejected = false;
                                                String? actualReason;

                                                if (rejectionReasonStr != null) {
                                                  final parts = rejectionReasonStr.split('::');
                                                  if (parts.length >= 3 && parts[1] == manager['id']) {
                                                    isOrganizerRejected = parts[0] == 'ORGANIZER_REJECTED';
                                                    isManagerRejected = parts[0] == 'MANAGER_REJECTED';
                                                    actualReason = parts.sublist(2).join('::');
                                                  }
                                                }

                                                if (isOrganizerRejected || isManagerRejected) {
                                                  return const SizedBox.shrink(); // Rejection boxes handled below the ListTile
                                                } else if (_currentEvent['assigned_manager_id'] == manager['id']) {
                                                  return const SizedBox.shrink(); // "Accepted" already handled or needs to be shown
                                                } else if (_currentEvent['assigned_manager_id'] == null) {
                                                  return ElevatedButton(
                                                    onPressed: () => _handleAcceptManager(manager['id']),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF1E4D40),
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                    ),
                                                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              }
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                      // Rejection or Assignment status boxes
                                      Builder(
                                        builder: (context) {
                                          final rejectionReasonStr = _currentEvent['rejection_reason'] as String?;
                                          bool isOrganizerRejected = false;
                                          bool isManagerRejected = false;
                                          String? actualReason;

                                          if (rejectionReasonStr != null) {
                                            final parts = rejectionReasonStr.split('::');
                                            if (parts.length >= 3 && parts[1] == manager['id']) {
                                              isOrganizerRejected = parts[0] == 'ORGANIZER_REJECTED';
                                              isManagerRejected = parts[0] == 'MANAGER_REJECTED';
                                              actualReason = parts.sublist(2).join('::');
                                            }
                                          }

                                          if (isManagerRejected) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.red[100]!),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.info_outline, color: Colors.red[400], size: 20),
                                                        const SizedBox(width: 8),
                                                        const Text(
                                                          'Application Update',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Reason: ${actualReason ?? "No reason provided"}',
                                                      style: TextStyle(color: Colors.red[700], height: 1.4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else if (isOrganizerRejected) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'You rejected this manager: $actualReason',
                                                  style: const TextStyle(color: Colors.grey),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
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
    status = status.toLowerCase();
    if (status.contains('deadline over')) return Colors.red;
    if (status.contains('acceptance started')) return Colors.blue;
    if (status.contains('assigned manager')) return Colors.green;
    return Colors.orange;
  }

  String _getDynamicStatus(Map<String, dynamic> event) {
    final String? deadlineStr = event['registration_deadline'];
    bool isPastDeadline = false;
    if (deadlineStr != null) {
      try {
        final deadline = DateTime.parse(deadlineStr);
        isPastDeadline = DateTime.now().isAfter(deadline);
      } catch (_) {}
    }

    if (event['assigned_manager_id'] != null) {
      return isPastDeadline ? 'Assigned manager & Deadline over' : 'Assigned manager';
    }

    final List<dynamic> managerIds = event['manager_ids'] ?? [];
    if (managerIds.isNotEmpty || event['rejection_reason'] != null) {
      return isPastDeadline ? 'Acceptance started & Deadline over' : 'Acceptance started';
    }

    if (isPastDeadline) {
      return 'Deadline over'; 
    }

    return 'Pending';
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
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildGalleryImage(url),
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

class _ExpandableText extends StatelessWidget {
  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableText({
    super.key,
    required this.text,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return Text('N/A', style: TextStyle(fontSize: 16, color: Colors.grey[700]));

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          height: 1.6,
        );
        final span = TextSpan(text: text, style: style);
        
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 10,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          return Text(text, style: style);
        }

        if (isExpanded) {
          return RichText(
            text: TextSpan(
              style: style,
              children: [
                TextSpan(text: '$text '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: const Text(
                      'Read less',
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

        // We want to truncate after exactly 10 lines and 7 words.
        // We find the offset for the end of the 9th line (start of 10th line)
        final pos10 = tp.getPositionForOffset(Offset(0, style.fontSize! * style.height! * 9.5)).offset;
        
        String lines1To9 = '';
        String line10Render = '';

        try {
          if (pos10 > 0 && pos10 < text.length) {
            lines1To9 = text.substring(0, pos10);
            String rest = text.substring(pos10).trimLeft();
            List<String> words10 = rest.split(RegExp(r'\s+'));
            if (words10.length > 7) {
              line10Render = words10.take(7).join(' ');
            } else {
              line10Render = rest;
            }
          } else {
             final words = text.split(' ');
             int target = words.length > 40 ? 40 : words.length ~/ 2;
             lines1To9 = words.take(target - 7).join(' ');
             line10Render = words.skip(target - 7).take(7).join(' ');
          }
        } catch (e) {
          lines1To9 = text.substring(0, text.length > 100 ? 100 : text.length);
          line10Render = '';
        }

        String truncatedText = lines1To9;
        if (truncatedText.isNotEmpty && !truncatedText.endsWith(' ') && !truncatedText.endsWith('\n')) {
             truncatedText += ' ';
        }
        truncatedText += '$line10Render....';

        return RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: truncatedText),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: onToggle,
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
      },
    );
  }
}
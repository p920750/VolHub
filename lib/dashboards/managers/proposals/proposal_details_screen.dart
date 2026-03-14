import 'package:flutter/material.dart';
import '../../../../services/event_manager_service.dart';
import '../../../../widgets/text_truncator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProposalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const ProposalDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<ProposalDetailsScreen> createState() => _ProposalDetailsScreenState();
}

class _ProposalDetailsScreenState extends State<ProposalDetailsScreen> {
  bool _isAccepting = false;
  bool _isApplied = false;
  bool _isOrganizerRejected = false;
  bool _isManagerRejected = false;
  String? _actualReason;
  String? _expandedFieldId;

  @override
  void initState() {
    super.initState();
    final userId = EventManagerService.client.auth.currentUser?.id;
    final managerIds = widget.event['manager_ids'] as List<dynamic>?;
    if (managerIds != null && managerIds.contains(userId)) {
      _isApplied = true;
    } else if (widget.event['manager_has_applied'] == true) {
      _isApplied = true;
    }
    
    // Parse the new serialized rejection format
    final rejectionStr = widget.event['rejection_reason'] as String?;
    if (rejectionStr != null && userId != null) {
      final parts = rejectionStr.split('::');
      if (parts.length >= 3 && parts[1] == userId) {
        if (parts[0] == 'ORGANIZER_REJECTED') {
          _isOrganizerRejected = true;
        } else if (parts[0] == 'MANAGER_REJECTED') {
          _isManagerRejected = true;
        }
        _actualReason = parts.sublist(2).join('::');
      }
    }
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null) return 'TBD';
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd/MM/yyyy').format(date);
      return '$formattedDate at ${timeStr ?? "TBD"}';
    } catch (e) {
      return 'TBD';
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      await EventManagerService.acceptEvent(widget.event['id'].toString());
      setState(() {
        _isApplied = true;
        _isAccepting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application sent successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isAccepting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final deadlineStr = widget.event['registration_deadline'];
    if (deadlineStr != null) {
      try {
        final deadline = DateTime.parse(deadlineStr.toString());
        final currentDiff = deadline.difference(DateTime.now()).inDays;
        if (currentDiff == 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot reject the accepted event only five days left')),
            );
          }
          return;
        }
      } catch (_) {}
    }

    final reasonController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Proposal Agreement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please state your reason for withdrawing from this event. The organizer will be notified.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Mandatory Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason is strictly required.')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Event', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isAccepting = true); // Repurpose loading state
      try {
        await EventManagerService.rejectEvent(widget.event['id'].toString(), reasonController.text.trim());
        if (mounted) {
          setState(() {
            _isManagerRejected = true;
            _actualReason = reasonController.text.trim();
            _isAccepting = false;
            // Optimistically update local view so button changes back
            widget.event['assigned_manager_id'] = null; 
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have withdrawn from this event.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAccepting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to withdraw: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.event['host'] as Map<String, dynamic>?;
    final images = (widget.event['image_url'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
    final title = widget.event['title'] ?? widget.event['name'] ?? 'Unknown Event';
    final location = widget.event['location'] ?? 'N/A';
    final dateTime = _formatDateTime(widget.event['date'], widget.event['time']);
    final budget = widget.event['budget'] ?? 'Not specified';
    final description = widget.event['description'] ?? '';
    final requirements = widget.event['requirements'] ?? '';
    final eventId = widget.event['id']?.toString() ?? 'unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Event Proposal Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) Name of the event
                      Text(
                        title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // 2) Event location
                      _buildInfoRow(Icons.location_on, 'Event Location: $location', fontSize: 16),
                      const SizedBox(height: 4),
                      // 3) Date and time
                      _buildInfoRow(Icons.calendar_today, 'Event Date: $dateTime', fontSize: 14),
                      const SizedBox(height: 4),
                      // 3b) Deadline for Acceptance
                      _buildInfoRow(
                        Icons.timer_outlined, 
                        'Deadline for Acceptance: ${widget.event['registration_deadline_formatted'] ?? 'Not set'}',
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4) budget range
            const Text('Budget Range:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(budget, style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // 5) Posted by who + profile link
            Row(
              children: [
                CircleAvatar(
                  radius: 12, 
                  backgroundImage: (host?['avatar_url'] != null && host!['avatar_url'].toString().isNotEmpty)
                      ? NetworkImage(host['avatar_url'])
                      : null,
                  child: (host?['avatar_url'] == null || host!['avatar_url'].toString().isEmpty)
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Posted by: ${host?['full_name'] ?? widget.event['host_name'] ?? 'Organizer'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 6) Event Description (10 lines truncation)
            const Text('Event Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextTruncator(
              text: description,
              maxLines: 10,
              charThreshold: 30,
              style: const TextStyle(fontSize: 15, height: 1.5),
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

            // 6) Company Requirements (10 lines truncation)
            const Text('Company Requirements:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextTruncator(
              text: requirements,
              maxLines: 10,
              charThreshold: 30,
              style: const TextStyle(fontSize: 15, height: 1.5),
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
            const SizedBox(height: 32),

            // 7) location images (270px x 168px)
            if (images.isNotEmpty) ...[
              const Text('Location Images:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _showEnlargedImage(context, images[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        width: 270,
                        height: 168,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 270,
                          height: 168,
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // 7.75) Organizer Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: (host?['profile_photo'] != null && host!['profile_photo'].toString().isNotEmpty)
                            ? NetworkImage(host['profile_photo'])
                            : null,
                        child: (host?['profile_photo'] == null || host!['profile_photo'].toString().isEmpty)
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Organizer Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      if (host?['id'] != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/host-profile-public',
                              arguments: {'hostId': host!['id']},
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View Profile', style: TextStyle(color: Color(0xFF1E4D40), fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    Icons.email_outlined, 
                    host?['email'] ?? 'No email provided',
                    textColor: host?['email'] != null ? Colors.blue : null,
                    onTap: host?['email'] != null 
                      ? () {
                          final String email = host!['email'].toString();
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: email,
                          );
                          _launchURL(emailUri.toString());
                        }
                      : null,
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.phone_outlined, 
                    host?['phone_number'] ?? 'No phone number provided',
                    onTap: host?['phone_number'] != null 
                      ? () => _launchURL('tel:${host?['phone_number']}') 
                      : null,
                  ),
                  if (host?['company_location'] != null && host!['company_location'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.location_on_outlined, host['company_location']),
                  ],
                ],
              ),
            ),
            if ((_isOrganizerRejected || _isManagerRejected) && widget.event['assigned_manager_id'] == null && _actualReason != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isOrganizerRejected ? 'Organizer Rejected Application' : 'You Withdrew/Rejected', 
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: $_actualReason',
                      style: TextStyle(color: Colors.red[800], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.event['status'] == 'finished' || widget.event['status'] == 'completed') ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Your Completion Report', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event['manager_completion_notes'] ?? 'No notes provided.',
                      style: TextStyle(color: Colors.green[800], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.event['status'] == 'rejected' && widget.event['organizer_feedback'] != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Completion Rejected by Organizer', 
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Feedback: ${widget.event['organizer_feedback']}',
                      style: TextStyle(color: Colors.red[800], fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please review the feedback and resubmit your completion report.',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // 8) "Ready to accept" button centrally aligned
            Center(
              child: _buildAcceptButton(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
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

  bool get _isPastDeadline {
    final deadlineStr = widget.event['registration_deadline'];
    if (deadlineStr == null) return false;
    try {
      final deadline = DateTime.parse(deadlineStr.toString());
      return DateTime.now().isAfter(deadline);
    } catch (_) {
      return false;
    }
  }

  bool get _isEventDatePassed {
    final dateStr = widget.event['date_raw'] ?? widget.event['date'];
    if (dateStr == null) return false;
    try {
      final eventDate = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      // If today or past
      final today = DateTime(now.year, now.month, now.day);
      final evDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
      return now.isAfter(eventDate) || today.isAtSameMomentAs(evDate);
    } catch (_) {
      return false;
    }
  }

  bool get _canRejectManager {
    final deadlineStr = widget.event['registration_deadline'];
    if (deadlineStr == null) return true;
    try {
      final deadline = DateTime.parse(deadlineStr.toString());
      return deadline.difference(DateTime.now()).inDays >= 5;
    } catch (_) {
      return true;
    }
  }

  Widget _buildAcceptButton() {
    final String? assignedManagerId = widget.event['assigned_manager_id'];
    final userId = EventManagerService.client.auth.currentUser?.id;
    final String status = widget.event['status']?.toString().toLowerCase() ?? 'pending';
    final hasOrganizerFeedback = widget.event['organizer_feedback'] != null;

    if (assignedManagerId == userId && userId != null) {
      if (status == 'finished') {
        return Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: const Text(
            'Sent for Confirmation',
            style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }

      if (status == 'completed') {
        return Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'Event Completed',
            style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }

      if (_isEventDatePassed || (status == 'rejected' && hasOrganizerFeedback)) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _showCompletionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4D40),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isAccepting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Mark as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!_isPastDeadline && _canRejectManager && !(status == 'rejected' && hasOrganizerFeedback)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAccepting ? null : _showRejectDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        );
      }
      if (_isPastDeadline) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'Accepted & Acceptance closed',
                style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'Accepted',
              style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          if (_canRejectManager) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _showRejectDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isAccepting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                  : const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      );
    }

    if (_isManagerRejected || _isOrganizerRejected) {
      return Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'Rejected',
          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (assignedManagerId != null && assignedManagerId != userId) {
      return Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          _isPastDeadline ? 'Assigned manager & Acceptance closed' : 'Assigned manager',
          style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isApplied) {
      return Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Waiting for approval',
          style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isPastDeadline) {
      return Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'Acceptance closed',
          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAccepting ? null : _handleAccept,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF001529),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isAccepting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Ready to accept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _showCompletionDialog() async {
    final notesController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a brief summary of the completed tasks and any important notes for the organizer.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Completion notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter completion notes.')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4D40)),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isAccepting = true);
      try {
        await EventManagerService.markEventAsFinished(
          widget.event['id'].toString(), 
          notesController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _isAccepting = false;
            widget.event['status'] = 'finished';
            widget.event['manager_completion_notes'] = notesController.text.trim();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completion report sent to organizer.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAccepting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Try to launch without canLaunchUrl first as it can be flaky on some Android versions
      final bool launched = await launchUrl(
        url, 
        mode: LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch mail app for $urlString')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching $urlString: $e')),
        );
      }
    }
  }

  Widget _buildContactRow(IconData icon, String text, {VoidCallback? onTap, Color? textColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor ?? (onTap != null ? const Color(0xFF1E4D40) : Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14, 
                color: textColor ?? (onTap != null ? const Color(0xFF1E4D40) : Colors.grey[800]),
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {double fontSize = 14, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: fontSize, color: color ?? Colors.grey),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize, color: color ?? Colors.grey),
          ),
        ),
      ],
    );
  }
}

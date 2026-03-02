import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/event_manager_service.dart';
import '../../../../widgets/text_truncator.dart';

class ManagerProposalCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onStatusChanged;

  const ManagerProposalCard({
    super.key,
    required this.event,
    required this.onStatusChanged,
  });

  @override
  State<ManagerProposalCard> createState() => _ManagerProposalCardState();
}

class _ManagerProposalCardState extends State<ManagerProposalCard> {
  bool _isAccepting = false;
  bool _isApplied = false;
  bool _isOrganizerRejected = false;
  bool _isManagerRejected = false;
  String? _actualReason;
  String? _expandedFieldId;

  @override
  void initState() {
    super.initState();
    // Check if manager is already in manager_ids or has a pending application
    final userId = EventManagerService.client.auth.currentUser?.id;
    final managerIds = widget.event['manager_ids'] as List<dynamic>?;
    if (managerIds != null && managerIds.contains(userId)) {
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
      await EventManagerService.acceptEvent(widget.event['id']);
      setState(() {
        _isApplied = true;
        _isAccepting = false;
      });
      widget.onStatusChanged();
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
            if (widget.event is Map) {
              (widget.event as Map)['assigned_manager_id'] = null;
            }
          });
          widget.onStatusChanged();
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

  void _showFullOverview() {
    Navigator.pushNamed(
      context, 
      '/manager-proposal-details', 
      arguments: widget.event
    ).then((_) => widget.onStatusChanged());
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.event['host'] as Map<String, dynamic>?;
    final title = widget.event['title'] ?? widget.event['name'] ?? 'Unknown Event';
    final location = widget.event['location'] ?? 'N/A';
    final dateTime = _formatDateTime(widget.event['date'], widget.event['time']);
    final description = widget.event['description'] ?? '';
    final requirements = widget.event['requirements'] ?? '';
    final eventId = widget.event['id']?.toString() ?? 'unknown';

    return GestureDetector(
      onTap: _showFullOverview,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Name of the event
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // 2) Event location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Event Location: $location', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),

              // 3) Date and time
              Row(
                children: [
                   const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Event Date: $dateTime', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              
              // 3b) Deadline
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Deadline for Acceptance: ${widget.event['registration_deadline_formatted'] ?? 'Not set'}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

    

              // 5) Event Description (5 lines, 30 chars truncation)
              const Text('Event Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextTruncator(
                text: description,
                maxLines: 5,
                charThreshold: 30,
                style: const TextStyle(fontSize: 14),
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
              const SizedBox(height: 12),

              // 6) Company Requirements (5 lines, 30 chars truncation)
              const Text('Company Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextTruncator(
                text: requirements,
                maxLines: 5,
                charThreshold: 30,
                style: const TextStyle(fontSize: 14),
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
              // 7) Rejection Reason (if applicable)
              if ((_isOrganizerRejected || _isManagerRejected) && widget.event['assigned_manager_id'] == null && _actualReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _isOrganizerRejected ? 'Organizer Rejected Application' : 'You Withdrew/Rejected', 
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${_actualReason ?? widget.event['rejection_reason']}',
                        style: TextStyle(color: Colors.red[800], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 8) Ready to accept button at the bottom right
              Align(
                alignment: Alignment.bottomRight,
                child: _buildAcceptButton(),
              ),
            ],
          ),
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

  Widget _buildAcceptButton({bool centered = false}) {
    final String? assignedManagerId = widget.event['assigned_manager_id'];
    final userId = EventManagerService.client.auth.currentUser?.id;

    if (assignedManagerId == userId && userId != null) {
      if (_isPastDeadline) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'Accepted & Acceptance closed',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'Accepted',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          if (_canRejectManager) ...[
            ElevatedButton(
              onPressed: _isAccepting ? null : _showRejectDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isAccepting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                : const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      );
    }

    if (_isManagerRejected || _isOrganizerRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'Rejected',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (assignedManagerId != null && assignedManagerId != userId) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          _isPastDeadline ? 'Assigned manager & Acceptance closed' : 'Assigned manager',
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Waiting for approval',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      );
    }


    if (_isPastDeadline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'Acceptance closed',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isAccepting ? null : _handleAccept,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF001529),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isAccepting
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Ready to accept'),
    );
  }
}

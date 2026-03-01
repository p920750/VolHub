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

  @override
  void initState() {
    super.initState();
    // Check if manager is already in manager_ids or has a pending application
    final userId = EventManagerService.client.auth.currentUser?.id;
    final managerIds = widget.event['manager_ids'] as List<dynamic>?;
    if (managerIds != null && managerIds.contains(userId)) {
      _isApplied = true;
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
                  Text(location, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),

              // 3) Date and time
              Row(
                children: [
                   const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateTime, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

              // 4) Posted by who + profile link
              Row(
                children: [
                  const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                  const SizedBox(width: 8),
                  Text(
                    'Posted by: ${host?['full_name'] ?? 'Organizer'}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
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
              ),
              const SizedBox(height: 12),

              // 6) Company Requirements (5 lines, 30 chars truncation)
              const Text('Company Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextTruncator(
                text: requirements,
                maxLines: 5,
                charThreshold: 30,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // 7) Ready to accept button at the bottom right
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

  Widget _buildAcceptButton({bool centered = false}) {
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

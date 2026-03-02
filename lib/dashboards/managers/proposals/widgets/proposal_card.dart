import 'package:flutter/material.dart';
import '../../../../services/event_manager_service.dart';
import '../../post_events/post_events_screen.dart';
import '../../../../widgets/safe_avatar.dart';

class ProposalCard extends StatefulWidget {
  final Map<String, dynamic> application;
  final VoidCallback onReject;

  const ProposalCard({
    super.key, 
    required this.application,
    required this.onReject,
  });

  @override
  State<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard> {
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    final status = (widget.application['status'] ?? 'pending').toString().toLowerCase();
    final host = widget.application['host'] as Map<String, dynamic>?;
    
    Color statusColor;
    switch (status) {
      case 'accepted': statusColor = Colors.blue; break;
      case 'active': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'pending': statusColor = Colors.orange; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.application['name'] ?? 'Unknown Event',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(widget.application['location'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(widget.application['date'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            if (host != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SafeAvatar(
                      radius: 16,
                      imageUrl: host['profile_photo'] ?? 'https://i.pravatar.cc/150?u=${host['id']}',
                      name: host['full_name'] ?? 'Organizer',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(host['full_name'] ?? 'Organizer', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Posted by Organizer', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to organizer profile if exists
                      },
                      child: const Text('View Profile', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ${widget.application['budget'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    if (status == 'pending' || status == 'confirmed' || status == 'accepted') ...[
                      if (widget.application['manager_id'] != null) ...[
                        if (widget.application['manager_id'] == EventManagerService.client.auth.currentUser?.id) ...[
                          _buildActionButton(
                            onPressed: () => _handleRepost(),
                            icon: Icons.send,
                            label: 'Repost',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text('APPROVED', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.blue,
                          ),
                        ] else ...[
                          const Chip(
                            label: Text('ASSIGNED', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.redAccent,
                          ),
                        ],
                      ] else ...[
                        _buildActionButton(
                          onPressed: () => _handleAccept(),
                          icon: Icons.check,
                          label: 'Accept',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          onPressed: () => _showRejectDialog(),
                          icon: Icons.close,
                          label: 'Reject',
                          color: Colors.red,
                        ),
                      ],
                    ] else if (status == 'active') ...[
                      const Chip(
                        label: Text('ACTIVE ON DASHBOARD', style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.green,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (widget.application['manager_id'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: widget.application['manager_id'] == EventManagerService.client.auth.currentUser?.id
                  ? const Text(
                      'Approved',
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'Assigned to this ${widget.application['assigned_manager']?['company_name'] ?? 'Company'}',
                      style: TextStyle(color: Colors.red[700], fontSize: 13, fontWeight: FontWeight.bold),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    try {
      await EventManagerService.acceptOrganizerRequest(widget.application['id']);
      widget.onReject(); // Simplified: using same callback to refresh
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleRepost() async {
    // Navigate to post event screen with pre-filled data
    // For now, let's just update the status to active directly 
    // or navigate to PostEventsScreen if we want to allow editing.
    // The user mentioned: "allows to fetch details in post_event.. and before creating an event and sending to volunteer dashboard they can edit it."
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEventsScreen(editEvent: widget.application),
      ),
    ).then((_) => widget.onReject());
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this proposal.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                return;
              }
              try {
                await EventManagerService.rejectOrganizerRequest(widget.application['id'], reasonController.text.trim());
                if (context.mounted) Navigator.pop(context);
                widget.onReject();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

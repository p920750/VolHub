import 'package:flutter/material.dart';
import '../../../../services/event_manager_service.dart';

class EventRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;

  const EventRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
  });

  @override
  State<EventRequestCard> createState() => _EventRequestCardState();
}

class _EventRequestCardState extends State<EventRequestCard> {
  bool _isAccepting = false;
  bool _proposalSent = false;

  void _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      await EventManagerService.acceptEvent(widget.request['id']);
      if (mounted) {
        setState(() => _proposalSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event Accepted! Check your proposals.')),
        );
        widget.onAccept();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    widget.request['title'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  widget.request['budget'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(widget.request['date'], style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(widget.request['location'], style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.request['description'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Organizer Details:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14),
                const SizedBox(width: 4),
                Text(widget.request['host']?['full_name'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.email_outlined, size: 14),
                const SizedBox(width: 4),
                Text(widget.request['host']?['email'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14),
                const SizedBox(width: 4),
                Text(widget.request['host']?['phone_number'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.location_city_outlined, size: 14),
                const SizedBox(width: 4),
                Text(widget.request['host']?['country_code'] ?? '', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                    const SizedBox(width: 8),
                    Text(
                      'Posted by ${widget.request['host_name'] ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: (_proposalSent || _isAccepting) ? null : _handleAccept,
                  icon: Icon(_proposalSent ? Icons.check : Icons.handshake_outlined, size: 16),
                  label: _isAccepting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_proposalSent ? 'Accepted' : 'Accept'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: _proposalSent ? Colors.green : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

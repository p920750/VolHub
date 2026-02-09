import 'package:flutter/material.dart';

class EventRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onSendProposal;

  const EventRequestCard({
    super.key,
    required this.request,
    required this.onSendProposal,
  });

  @override
  State<EventRequestCard> createState() => _EventRequestCardState();
}

class _EventRequestCardState extends State<EventRequestCard> {
  bool _proposalSent = false;

  void _showProposalDialog() {
    final messageController = TextEditingController();
    final budgetController = TextEditingController(text: widget.request['budget']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Proposal for ${widget.request['title']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Your Proposal Budget',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message to Organizer',
                  hintText: 'Describe why you are a good fit...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _proposalSent = true;
              });
              widget.onSendProposal();
            },
            child: const Text('Send Proposal'),
          ),
        ],
      ),
    );
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
                      'Posted by ${widget.request['posted_by']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _proposalSent ? null : _showProposalDialog,
                  icon: Icon(_proposalSent ? Icons.check : Icons.send, size: 16),
                  label: Text(_proposalSent ? 'Proposal Sent' : 'Proposal'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

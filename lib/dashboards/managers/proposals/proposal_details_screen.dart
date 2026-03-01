import 'package:flutter/material.dart';
import '../../../../services/event_manager_service.dart';
import '../../../../widgets/text_truncator.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
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
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 3) Date and time
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(dateTime, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
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
                const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                const SizedBox(width: 8),
                Text(
                  'Posted by: ${host?['full_name'] ?? 'Organizer'}',
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
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
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

  Widget _buildAcceptButton() {
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
}

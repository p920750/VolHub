import 'package:flutter/material.dart';
import '../../../../services/host_service.dart';

class MatchingEventsWidget extends StatefulWidget {
  const MatchingEventsWidget({super.key});

  @override
  State<MatchingEventsWidget> createState() => _MatchingEventsWidgetState();
}

class _MatchingEventsWidgetState extends State<MatchingEventsWidget> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await HostService.getMatchingEventsForManager();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No matching events found from organizers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                event['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              event['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.label, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(event['category'], style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(event['date'], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event['budget'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Organizer Posted',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
                // Navigate to event details if needed
            },
          ),
        );
      },
    );
  }
}

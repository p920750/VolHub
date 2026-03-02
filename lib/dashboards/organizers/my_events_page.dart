import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/host_service.dart';
import 'event_detail_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _expandedFieldId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await HostService.getEvents();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/organizer-dashboard');
            }
          },
        ),
        title: const Text(
          'My Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getFilteredEvents().isEmpty
              ? const Center(child: Text('No requests posted yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _getFilteredEvents().length,
                  itemBuilder: (context, index) {
                    final event = _getFilteredEvents()[index];
                    return _buildEventCard(event);
                  },
                ),
    );
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    return _events.where((event) {
      final status = _getDynamicStatus(event);
      if (status == 'Acceptance started & Deadline over') return false;
      return true;
    }).toList();
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
        if (result == true) {
          _loadEvents();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event['title'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001529)),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) => _handleMenuAction(value, event),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Event Location: ${event['location']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Event Date: ${event['date_time_formatted'] ?? 'TBD'}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline for Acceptance: ${event['registration_deadline_formatted'] ?? 'Not set'}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Event Description:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _MyEventsExpandableText(
                text: event['description'] ?? 'No description',
                isExpanded: _expandedFieldId == '${event['id']}_description',
                onToggle: () {
                  setState(() {
                    if (_expandedFieldId == '${event['id']}_description') {
                      _expandedFieldId = null;
                    } else {
                      _expandedFieldId = '${event['id']}_description';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Company Requirements:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _MyEventsExpandableText(
                text: event['requirements'] ?? 'No requirements',
                isExpanded: _expandedFieldId == '${event['id']}_requirements',
                onToggle: () {
                  setState(() {
                    if (_expandedFieldId == '${event['id']}_requirements') {
                      _expandedFieldId = null;
                    } else {
                      _expandedFieldId = '${event['id']}_requirements';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (_getDynamicStatus(event) == 'Acceptance started') {
                          int daysLeft = 999;
                          if (event['registration_deadline'] != null) {
                            try {
                              daysLeft = DateTime.parse(event['registration_deadline']).difference(DateTime.now()).inDays;
                            } catch (_) {}
                          }
                          if (daysLeft <= 5) {
                            return const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                SizedBox(width: 4),
                                Expanded(child: Text('Please accept a manager', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_getDynamicStatus(event)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDynamicStatus(event),
                      style: TextStyle(
                        color: _getStatusColor(_getDynamicStatus(event)),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> event) {
    if (action == 'edit') {
       Navigator.pushNamed(context, '/edit-event', arguments: event).then((_) => _loadEvents());
    } else if (action == 'delete') {
      _showDeleteConfirmation(event['id']);
    }
  }

  Future<void> _showDeleteConfirmation(String id) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await HostService.deleteEvent(id);
              _loadEvents();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('deadline over')) return Colors.red;
    if (status.contains('acceptance started')) return Colors.blue;
    if (status.contains('assigned manager')) return Colors.green;
    return Colors.orange;
  }
}

class _MyEventsExpandableText extends StatelessWidget {
  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _MyEventsExpandableText({
    super.key,
    required this.text,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const Text('N/A');

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = const TextStyle(fontSize: 13, color: Colors.black87);
        final span = TextSpan(text: text, style: style);
        
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 5,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          // If it naturally fits within 5 lines (or less), just show it
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Need to truncate exactly at the 5th line, 7th word.
        // Get the position of the end of the 4th line (or start of 5th)
        final pos5 = tp.getPositionForOffset(Offset(0, style.fontSize! * 1.5 * 4)).offset;
        
        String lines1To4 = '';
        String line5Render = '';

        try {
          if (pos5 > 0 && pos5 < text.length) {
            lines1To4 = text.substring(0, pos5);
            String rest = text.substring(pos5).trimLeft();
            List<String> words5 = rest.split(RegExp(r'\s+'));
            if (words5.length > 7) {
              line5Render = words5.take(7).join(' ');
            } else {
              line5Render = rest;
            }
          } else {
             // Fallback if measurement somewhat failed
             final words = text.split(' ');
             int target = words.length > 40 ? 40 : words.length ~/ 2;
             lines1To4 = words.take(target - 7).join(' ');
             line5Render = words.skip(target - 7).take(7).join(' ');
          }
        } catch (e) {
          // Absolute fallback to prevent UI crash
          lines1To4 = text.substring(0, text.length > 100 ? 100 : text.length);
          line5Render = '';
        }

        String truncatedText = lines1To4;
        if (truncatedText.isNotEmpty && !truncatedText.endsWith(' ') && !truncatedText.endsWith('\n')) {
            truncatedText += ' ';
        }
        truncatedText += '$line5Render....';

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
                      fontSize: 13,
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

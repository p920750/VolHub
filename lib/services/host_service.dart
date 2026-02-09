import 'package:flutter/foundation.dart';

class HostService {
  // Mock data for events
  static final List<Map<String, dynamic>> _events = [
    {
      'title': 'Neon Summer Festival',
      'date': 'Aug 15, 2026',
      'location': 'Miami Beach, FL',
      'stats': '12 Managers Applied',
      'status': 'Active',
      'imageUrl': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500',
    },
    {
      'title': 'Elite Tech Summit',
      'date': 'Oct 20, 2026',
      'location': 'Silicon Valley, CA',
      'stats': '5 Managers Applied',
      'status': 'Pending',
      'imageUrl': 'https://images.unsplash.com/photo-1540575861501-7ad060e39fe1?w=500',
    },
  ];

  static List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  static void addEvent(Map<String, dynamic> event) {
    _events.add(event);
    if (kDebugMode) print('Event added: ${event['title']}');
  }
}

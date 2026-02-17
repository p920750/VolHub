import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class HostService {
  static Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final userData = await SupabaseService.getUserFromUsersTable();
      final String role = userData?['role'] ?? 'host';

      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = 
          SupabaseService.client.from('events').select();

      // If host/organizer, only see their own events
      if (role == 'host' || role == 'organizer') {
        query = query.eq('manager_id', user.id);
      }
      
      // Managers can see all events (no filter)

      final response = await query.order('created_at', ascending: false);
      
      // Map database columns to the format expected by the UI
      return response.map((e) => {
        'id': e['id'],
        'title': e['name'],
        'date': e['date'] != null ? _formatDate(e['date']) : 'TBD',
        'location': e['location'] ?? 'Online',
        'stats': '0 Managers Applied', // Placeholder for now
        'status': e['status'] == 'upcoming' ? 'Pending' : (e['status'] == 'active' ? 'Active' : 'Completed'),
        'imageUrl': e['image_url'] ?? 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
        'budget': e['budget'] ?? 'Not specified',
        'requirements': e['requirements'] ?? 'None specified',
        'description': e['description'] ?? 'No description',
        'host_name': e['host_name'] ?? 'Host',
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching events: $e');
      return [];
    }
  }

  static Future<void> addEvent(Map<String, dynamic> event) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await SupabaseService.client.from('events').insert({
        'name': event['title'],
        'location': event['location'],
        'date': event['date_raw'], // Expecting ISO string or DateTime
        'description': event['description'],
        'manager_id': user.id,
        'status': 'upcoming',
        'budget': event['budget'],
        'requirements': event['requirements'],
        'image_url': event['imageUrl'],
        'host_name': event['host_name'],
      });
      
      if (kDebugMode) print('Event added to Supabase: ${event['title']}');
    } catch (e) {
      if (kDebugMode) print('Error adding event: $e');
      rethrow;
    }
  }

  static String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return isoString;
    }
  }
}

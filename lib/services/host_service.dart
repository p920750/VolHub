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
      if (role == 'host' || role == 'organizer' || role == 'manager') {
        query = query.eq('user_id', user.id);
      }
      
      // Managers can see all events (no filter)

      final response = await query.order('created_at', ascending: false);
      
      // Map database columns to the format expected by the UI
      return response.map((e) => {
        'id': e['id'],
        'title': e['name'],
        'description': e['description'],
        'requirements': e['requirements'],
        'budget': e['budget'],
        'host_name': e['host_name'],
        'imageUrl': e['image_url'], // Added for HostDashboardPage compatibility
        'image_url': e['image_url'],
        'date': e['date'] != null ? _formatDate(e['date']) : 'TBD',
        'date_raw': e['date'], // Keep raw ISO string for editing
        'location': e['location'] ?? 'Online',
        'stats': '0 Managers Applied', // Placeholder for now
        'status': (e['status'] ?? 'pending').toString().toLowerCase(),
        'rejection_reason': e['rejection_reason'],
        'manager_id': e['user_id'],
        'assigned_manager_id': e['assigned_manager_id'],
        'user_id': e['user_id'],
        'manager_ids': e['manager_ids'],
        'volunteer_ids': e['volunteer_ids'],
        'category': e['category'] ?? 'Other',
        'time': (e['time'] == null || e['time'].toString().trim().isEmpty || e['time'] == 'TBD') ? 'TBD' : e['time'],
        'posted_at': e['posted_at'] ?? (e['created_at'] != null ? _formatDateTimeDetailed(e['created_at']) : 'N/A'),
        'date_time_formatted': _formatDateTimeForMyEvents(e['date'], e['time']),
        'registration_deadline_formatted': _formatDeadlineForMyEvents(e['registration_deadline']),
        'registration_deadline': e['registration_deadline'],
        'created_at': e['created_at'],
        'created_at_formatted': e['created_at'] != null ? _formatDateTimeDetailed(e['created_at']) : 'N/A',
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
        'date': event['date'], // Expecting ISO string or DateTime
        'description': event['description'],
        'user_id': user.id,
        'status': 'pending',
        'budget': event['budget'],
        'requirements': event['requirements'],
        'image_url': event['imageUrl'],
        'host_name': event['host_name'],
        'category': event['category'],
        'time': event['time'],
        'posted_at': event['posted_at'],
        'registration_deadline': event['registration_deadline'],
      });
      
      if (kDebugMode) print('Event added to Supabase: ${event['title']}');
    } catch (e) {
      if (kDebugMode) print('Error adding event: $e');
      rethrow;
    }
  }

  static Future<void> updateEvent(String id, Map<String, dynamic> event) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await SupabaseService.client.from('events').update({
        'name': event['title'],
        'location': event['location'],
        'date': event['date'],
        'description': event['description'],
        'budget': event['budget'],
        'requirements': event['requirements'],
        'image_url': event['image_url'],
        'category': event['category'],
        'time': event['time'],
        'registration_deadline': event['registration_deadline'],
      }).eq('id', id);
      
      if (kDebugMode) print('Event updated in Supabase: ${event['title']}');
    } catch (e) {
      if (kDebugMode) print('Error updating event: $e');
      rethrow;
    }
  }

  static Future<void> deleteEvent(String id) async {
    try {
      await SupabaseService.client.from('events').delete().eq('id', id);
      if (kDebugMode) print('Event deleted from Supabase: $id');
    } catch (e) {
      if (kDebugMode) print('Error deleting event: $e');
      rethrow;
    }
  }

  static Future<void> updateEventImages(String id, String imageUrls) async {
    try {
      await SupabaseService.client.from('events').update({
        'image_url': imageUrls,
      }).eq('id', id);
      if (kDebugMode) print('Event images updated in Supabase: $id');
    } catch (e) {
      if (kDebugMode) print('Error updating images: $e');
      rethrow;
    }
  }

  static Future<void> confirmManager(String eventId, String managerId) async {
    try {
      await SupabaseService.client.rpc('append_manager_to_event', params: {
        'event_id': eventId,
        'manager_id': managerId,
      });
      
      if (kDebugMode) print('Manager $managerId added to event $eventId');
    } catch (e) {
      if (kDebugMode) print('Error confirming manager: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getManagerDetails(String managerId) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', managerId)
          .maybeSingle();
      return response;
    } catch (e) {
      if (kDebugMode) print('Error fetching manager details: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getEventApplications(String eventId) async {
    try {
      // 1. Fetch the event to get the manager_ids array
      final eventResponse = await SupabaseService.client
          .from('events')
          .select('manager_ids, rejection_reason')
          .eq('id', eventId)
          .maybeSingle();

      if (eventResponse == null) return [];

      final List<dynamic> managerIds = List<dynamic>.from(eventResponse['manager_ids'] ?? []);
      
      // Inject the rejected manager back into the display pool if the organizer rejected them
      final String? rejectionReason = eventResponse['rejection_reason'];
      if (rejectionReason != null && rejectionReason.startsWith('ORGANIZER_REJECTED::')) {
        final parts = rejectionReason.split('::');
        if (parts.length >= 3) {
          final rejectedManagerId = parts[1];
          if (!managerIds.contains(rejectedManagerId)) {
            managerIds.add(rejectedManagerId);
          }
        }
      }

      if (managerIds.isEmpty) return [];

      // 2. Fetch all users whose IDs are in the manager_ids array
      final usersResponse = await SupabaseService.client
          .from('users')
          .select()
          .inFilter('id', managerIds.map((id) => id.toString()).toList());

      // 3. Map into the 'users' nested format expected by the UI
      return (usersResponse as List).map((user) => {
        'users': user,
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event applicants from array: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMatchingEventsForManager() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      // 1. Get manager's categories
      final userData = await SupabaseService.getUserFromUsersTable();
      if (userData == null) return [];
      
      final List<String> managerCategories = (userData['company_category'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
      
      if (managerCategories.isEmpty) return [];

      // 2. Fetch events that match manager's categories and are pending
      final response = await SupabaseService.client
          .from('events')
          .select()
          .eq('status', 'pending')
          .inFilter('category', managerCategories)
          .not('user_id', 'eq', user.id) // Exclude events created by this user
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => {
        'id': e['id'],
        'title': e['name'],
        'description': e['description'],
        'requirements': e['requirements'],
        'date': e['date'] != null ? _formatDate(e['date']) : 'TBD',
        'time': e['time'],
        'date_time_formatted': _formatDateTimeForMyEvents(e['date'], e['time']),
        'registration_deadline': e['registration_deadline'],
        'registration_deadline_formatted': _formatDeadlineForMyEvents(e['registration_deadline']),
        'location': e['location'] ?? 'Online',
        'status': e['status'] == 'upcoming' ? 'Pending' : (e['status'] == 'active' ? 'Active' : 'Completed'),
        'imageUrl': e['image_url'] ?? 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
        'budget': e['budget'] ?? 'Not specified',
        'category': e['category'] ?? 'Other',
        'host_name': e['host_name'] ?? 'Organizer',
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching matching events: $e');
      return [];
    }
  }

  static Future<void> acceptManager(String eventId, String managerId) async {
    try {
      await SupabaseService.client.from('events').update({
        'assigned_manager_id': managerId,
        'rejection_reason': null,
      }).eq('id', eventId);
      if (kDebugMode) print('Organizer assigned manager: $managerId to event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error assigning manager: $e');
      rethrow;
    }
  }

  static Future<void> rejectManager(String eventId, String managerId, String reason) async {
    try {
      final serializedReason = 'ORGANIZER_REJECTED::$managerId::$reason';
      await SupabaseService.client.from('events').update({
        'assigned_manager_id': null,
        'rejection_reason': serializedReason,
      }).eq('id', eventId);
      
      // The user explicitly instructed to delete the manager ID from the manager_ids list when organizer rejects
      await SupabaseService.client.rpc('remove_manager_from_event', params: {
        'event_id': eventId,
        'manager_id': managerId,
      });

      if (kDebugMode) print('Organizer rejected manager: $managerId from event: $eventId with reason: $reason');
    } catch (e) {
      if (kDebugMode) print('Error rejecting manager: $e');
      rethrow;
    }
  }

  static String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'TBD';
    try {
      final DateTime date = dateInput is DateTime ? dateInput : DateTime.parse(dateInput.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateInput.toString();
    }
  }

  static String _formatDateTimeDetailed(dynamic dateTimeInput) {
    if (dateTimeInput == null) return 'N/A';
    try {
      final DateTime date = dateTimeInput is DateTime ? dateTimeInput : DateTime.parse(dateTimeInput.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute:$second';
    } catch (e) {
      return dateTimeInput.toString();
    }
  }

  static String _formatDateTimeForMyEvents(dynamic dateInput, String? timeStr) {
    if (dateInput == null) return 'TBD';
    try {
      final DateTime date = dateInput is DateTime ? dateInput : DateTime.parse(dateInput.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final String time = (timeStr == null || timeStr == 'TBD' || timeStr.isEmpty) ? 'TBD' : timeStr;
      return '$day/$month/$year at $time';
    } catch (e) {
      return '${dateInput.toString()} at ${timeStr ?? "TBD"}';
    }
  }

  static String _formatDeadlineForMyEvents(dynamic dateInput) {
    if (dateInput == null) return 'Not set';
    try {
      final DateTime date = dateInput is DateTime ? dateInput : DateTime.parse(dateInput.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      
      final hour24 = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = hour24 >= 12 ? 'pm' : 'am';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final hourStr = hour12.toString().padLeft(2, '0');
      
      return '$day/$month/$year on or before $hourStr:$minute $ampm';
    } catch (e) {
      return dateInput.toString();
    }
  }
}

import 'package:flutter/material.dart';
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
          SupabaseService.client.from('events').select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)');

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
        'registration_deadline_formatted': formatDeadlineForMyEvents(e['registration_deadline']),
        'registration_deadline': e['registration_deadline'],
        'created_at': e['created_at'],
        'created_at_formatted': e['created_at'] != null ? _formatDateTimeDetailed(e['created_at']) : 'N/A',
        'manager_completion_notes': e['manager_completion_notes'],
        'organizer_feedback': e['organizer_feedback'],
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

  static Stream<List<Map<String, dynamic>>> getManagerDetailsStream(String managerId) {
    return SupabaseService.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', managerId);
  }

  static Stream<List<Map<String, dynamic>>> getEventApplicationsStream(String eventId) {
    return SupabaseService.client
        .from('event_applications')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId);
  }

  static Stream<List<Map<String, dynamic>>> getEventStream(String eventId) {
    return SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('id', eventId);
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
      if (kDebugMode) print('Fetching event applications for eventId: $eventId');
      
      final eventResponse = await SupabaseService.client
          .from('events')
          .select('manager_ids, rejection_reason')
          .eq('id', eventId)
          .maybeSingle();

      if (kDebugMode) print('Event response: $eventResponse');
      if (eventResponse == null) return [];

      final List<dynamic> managerIds = List<dynamic>.from(eventResponse['manager_ids'] ?? []);
      
      // Inject the rejected manager back into the display pool if the organizer or manager rejected
      final String? rejectionReason = eventResponse['rejection_reason'];
      if (rejectionReason != null) {
        final parts = rejectionReason.split('::');
        if (parts.length >= 3) {
          final rejectedManagerId = parts[1];
          if (!managerIds.contains(rejectedManagerId)) {
            managerIds.add(rejectedManagerId);
          }
        }
      }

      // Fetch applied managers from event_applications
      final applicationsResponse = await SupabaseService.client
          .from('event_applications')
          .select('manager_id')
          .eq('event_id', eventId);
          
      if (kDebugMode) print('Applications response: $applicationsResponse');
          
      final appliedIds = (applicationsResponse as List)
          .map((e) => e['manager_id'])
          .where((id) => id != null)
          .toList();
          
      for (var id in appliedIds) {
        if (!managerIds.contains(id)) managerIds.add(id);
      }

      if (kDebugMode) print('Final manager IDs: $managerIds');

      if (managerIds.isEmpty) return [];

      // 2. Fetch all users whose IDs are in the manager_ids array
      final usersResponse = await SupabaseService.client
          .from('users')
          .select()
          .inFilter('id', managerIds.map((id) => id.toString()).toList());
          
      if (kDebugMode) print('Users response: $usersResponse');

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
          .select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)')
          .eq('status', 'pending')
          .inFilter('category', managerCategories)
          .not('user_id', 'eq', user.id) // Exclude events created by this user
          .order('created_at', ascending: false);

      // 3. Fetch applications for this manager
      final appliedResponse = await SupabaseService.client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List).map((e) => e['event_id']).toSet();

      // Filter by Public Profile
      final List<Map<String, dynamic>> filteredResponse = (response as List).where((e) {
        final settings = e['host']?['settings'] as Map<String, dynamic>?;
        return settings?['public_profile'] ?? true;
      }).map((e) => Map<String, dynamic>.from(e)).toList();

      return filteredResponse.map((e) {
        final hostData = e['host'] as Map<String, dynamic>?;
        return {
          'id': e['id'],
          'title': e['name'],
          'description': e['description'],
          'requirements': e['requirements'],
          'date': e['date'] != null ? _formatDate(e['date']) : 'TBD',
          'time': e['time'],
          'date_time_formatted': _formatDateTimeForMyEvents(e['date'], e['time']),
          'registration_deadline': e['registration_deadline'],
          'registration_deadline_formatted': formatDeadlineForMyEvents(e['registration_deadline']),
          'location': e['location'] ?? 'Online',
          'status': (e['status'] ?? 'pending').toString().toLowerCase(),
          'imageUrl': e['image_url'] ?? 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
          'budget': e['budget'] ?? 'Not specified',
          'category': e['category'] ?? 'Other',
          'host_name': hostData?['full_name'] ?? e['host_name'] ?? 'Organizer',
          'host': hostData,
          'manager_has_applied': appliedIds.contains(e['id']),
          'assigned_manager_id': e['assigned_manager_id'],
          'rejection_reason': e['rejection_reason'],
          'manager_ids': e['manager_ids'],
          'manager_completion_notes': e['manager_completion_notes'],
          'organizer_feedback': e['organizer_feedback'],
        };
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

  static Future<int> getEventCountForHost(String hostId) async {
    try {
      final response = await SupabaseService.client
          .from('events')
          .select('id')
          .eq('user_id', hostId);
      
      return (response as List).length;
    } catch (e) {
      if (kDebugMode) print('Error fetching event count: $e');
      return 0;
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

  static String formatDeadlineForMyEvents(dynamic dateInput) {
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

  static String getEventDynamicStatus(Map<String, dynamic> event) {
    // 1. Check explicit statuses first
    final String status = event['status']?.toString().toLowerCase() ?? 'pending';
    if (status == 'finished') return 'Completed by Manager';
    if (status == 'completed') return 'Event Finished';
    if (status == 'rejected' && event['organizer_feedback'] != null) return 'Completion Rejected';

    // 2. Check for "In Progress" (Event is happening today)
    final dynamic eventDateRaw = event['date'];
    if (eventDateRaw != null) {
      try {
        final eventDate = DateTime.parse(eventDateRaw.toString());
        final now = DateTime.now();
        if (eventDate.year == now.year && eventDate.month == now.month && eventDate.day == now.day) {
          return 'In Progress';
        }
      } catch (_) {}
    }

    // 3. Check deadlines and assignment statuses
    final String? deadlineStr = event['registration_deadline'];
    bool isPastDeadline = false;
    if (deadlineStr != null && deadlineStr.isNotEmpty) {
      try {
        final deadline = DateTime.parse(deadlineStr);
        isPastDeadline = DateTime.now().isAfter(deadline);
      } catch (_) {}
    }

    if (event['assigned_manager_id'] != null) {
      return 'Assigned manager';
    }

    final dynamic managerIdsRaw = event['manager_ids'];
    final List<dynamic> managerIds = managerIdsRaw is List ? managerIdsRaw : [];
    if (managerIds.isNotEmpty || (event['rejection_reason'] != null && event['rejection_reason'].toString().isNotEmpty)) {
      return isPastDeadline ? 'Acceptance started & Deadline over' : 'Acceptance started';
    }

    if (isPastDeadline) {
      return 'Deadline over'; 
    }

    return 'Pending';
  }

  /// Organizer confirms that the event is completed.
  static Future<void> confirmEventCompletion(String eventId) async {
    try {
      await Supabase.instance.client.from('events').update({
        'status': 'completed',
      }).eq('id', eventId);
    } catch (e) {
      if (kDebugMode) print('Error confirming completion: $e');
      throw Exception('Failed to confirm completion: $e');
    }
  }

  /// Organizer rejects the event completion reported by the manager.
  static Future<void> rejectEventCompletion(String eventId, String feedback) async {
    try {
      await Supabase.instance.client.from('events').update({
        'status': 'rejected',
        'organizer_feedback': feedback,
      }).eq('id', eventId);
    } catch (e) {
      if (kDebugMode) print('Error rejecting completion: $e');
      throw Exception('Failed to reject completion: $e');
    }
  }

  static Color getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('deadline over')) return const Color(0xFFF44336); // Colors.red
    if (status.contains('acceptance started')) return const Color(0xFF2196F3); // Colors.blue
    if (status.contains('assigned manager')) return const Color(0xFF4CAF50); // Colors.green
    if (status == 'in progress') return const Color(0xFF9C27B0); // Colors.purple
    if (status == 'completed by manager') return const Color(0xFFFF9800); // Colors.orange
    if (status == 'event finished') return const Color(0xFF4CAF50); // Colors.green
    if (status == 'completion rejected') return const Color(0xFFF44336); // Colors.red
    return const Color(0xFFFF9800); // Colors.orange
  }
}

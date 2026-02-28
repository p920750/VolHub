import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class EventManagerService {
  static SupabaseClient get client => SupabaseService.client;

  /// Fetches dashboard statistics for the current event manager.
  /// Returns a Map with keys corresponding to the stats cards.
  static Future<Map<String, String>> getDashboardStats() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await SupabaseService.getUserFromUsersTable();
      final List<String> categories = (userData?['company_category'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      // 1. Pending Proposals (Matching categories)
      int pendingProposals = 0;
      if (categories.isNotEmpty) {
        final pendingResponse = await client
            .from('events')
            .select('id')
            .eq('status', 'pending')
            .neq('user_id', user.id) // Exclude own events
            .inFilter('category', categories);
        pendingProposals = (pendingResponse as List?)?.length ?? 0;
      }

      // 2. Accepted/Active Events (Assigned to this manager)
      final assignedResponse = await client
          .from('events')
          .select('id')
          .contains('manager_ids', '{${user.id}}');
      final acceptedProposals = (assignedResponse as List?)?.length ?? 0;

      // 3. Active Teams (Managed by this user)
      int activeTeams = 0;
      // Note: teams table is currently not used

      // 4. Total Members
      // Mocked for now or sum of team members
      int totalMembers = 0;

      // 5. Open Job Postings / Pending Applications (for events managed by this user)
      // This refers to the manager posting jobs for THEIR events to volunteers
      int openJobPostings = 0;
      int pendingApplications = 0;
      
      try {
        final eventsManaged = await client
            .from('events')
            .select('id')
            .contains('manager_ids', '{${user.id}}');
            
        if (eventsManaged != null && eventsManaged.isNotEmpty) {
          final eventIds = (eventsManaged as List?)?.map((e) => e['id']).toList() ?? [];
          
          final jobsResponse = await client
              .from('job_postings')
              .select('id')
              .inFilter('event_id', eventIds)
              .eq('status', 'open');
          openJobPostings = (jobsResponse as List?)?.length ?? 0;
          
          final appsResponse = await client
              .from('event_applications')
              .select('id')
              .inFilter('event_id', eventIds)
              .eq('status', 'pending');
          pendingApplications = (appsResponse as List?)?.length ?? 0;
        }
      } catch (e) {
        if (kDebugMode) print('Jobs/Applications fetch error: $e');
      }

      return {
        'Active Teams': activeTeams.toString(),
        'Total Members': totalMembers.toString(),
        'Open Job Postings': openJobPostings.toString(),
        'Pending Applications': pendingApplications.toString(),
        'Accepted Proposals': acceptedProposals.toString(),
        'Pending Proposals': pendingProposals.toString(),
      };
    } catch (e) {
      if (kDebugMode) print('Error fetching dashboard stats: $e');
      return {
        'Active Teams': '0',
        'Total Members': '0',
        'Open Job Postings': '0',
        'Pending Applications': '0',
        'Accepted Proposals': '0',
        'Pending Proposals': '0',
      };
    }
  }

  /// Fetches the list of teams managed by the current user.
  static Future<List<Map<String, dynamic>>> getTeams() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Mock data for now until 'teams' table is set up
      /*
      final response = await client
          .from('teams')
          .select()
          .eq('manager_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
      */
      
      return []; 
    } catch (e) {
      if (kDebugMode) print('Error fetching teams: $e');
      return [];
    }
  }

  /// Fetches recent applications for events managed by the current user.
  static Future<List<Map<String, dynamic>>> getRecentApplications() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      return [];
    } catch (e) {
      if (kDebugMode) print('Error fetching proposals: $e');
      return [];
    }
  }

  /// Fetches pending event requests that match the manager's categories.
  static Future<List<Map<String, dynamic>>> getEventRequests(List<String>? categories) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      if (categories == null || categories.isEmpty) return [];

      var query = client.from('events').select('*, host:users(*)').eq('status', 'pending');
      
      query = query.inFilter('category', categories);
      
      query = query.neq('user_id', user.id); // Exclude own events

      final response = await query.order('created_at', ascending: false);
      
      // Filter out events the manager has already accepted/applied for
      final appliedResponse = await client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List?)?.map((e) => e['event_id']).toSet() ?? {};

      return response.where((e) => !appliedIds.contains(e['id'])).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event requests: $e');
      return [];
    }
  }

  /// Fetches proposals for the manager: both pending requests in their categories 
  /// and events already assigned to them.
  static Future<List<Map<String, dynamic>>> getProposals() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final userData = await SupabaseService.getUserFromUsersTable();
      final List<String> categories = (userData?['company_category'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      const selectColumns = '*, host:users(*)'; 

      // 1. Pending events in manager's categories
      List<dynamic> pendingEvents = [];
      if (categories.isNotEmpty) {
        pendingEvents = await client
            .from('events')
            .select(selectColumns)
            .eq('status', 'pending')
            .neq('user_id', user.id) // Exclude own events
            .inFilter('category', categories);
      } else {
        if (kDebugMode) print('getProposals: No categories for manager ${user.id}');
      }

      // 2. Events assigned to this manager
      final assignedEvents = await client
          .from('events')
          .select(selectColumns)
          .contains('manager_ids', '{${user.id}}');

      // 3. Events this manager has applied for (via event_applications table)
      final appliedResponse = await client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List?)?.map((e) => e['event_id']).toList() ?? [];
      var appliedEvents = [];
      if (appliedIds.isNotEmpty) {
        appliedEvents = await client
            .from('events')
            .select(selectColumns)
            .inFilter('id', appliedIds);
      }

      // Combine and filter duplicates
      final Map<String, Map<String, dynamic>> allProposals = {};
      
      // Add pending events first
      for (var e in pendingEvents) {
        allProposals[e['id']] = Map<String, dynamic>.from(e);
      }
      
      // Add/overwrite with applied events (which might have different status)
      for (var e in appliedEvents) {
        allProposals[e['id']] = Map<String, dynamic>.from(e);
      }
      
      // Add/overwrite with explicitly assigned events
      for (var e in assignedEvents) {
        allProposals[e['id']] = Map<String, dynamic>.from(e);
      }

      final result = allProposals.values.toList();
      result.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      return result;
    } catch (e) {
      if (kDebugMode) print('Error fetching proposals: $e');
      return [];
    }
  }

  /// Manager accepts an event request from an organizer.
  static Future<void> acceptOrganizerRequest(String eventId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await SupabaseService.client.rpc('append_manager_to_event', params: {
        'event_id': eventId,
        'manager_id': user.id,
      });

      await client.from('events').update({
        'status': 'accepted',
      }).eq('id', eventId);
      
      if (kDebugMode) print('Manager accepted organizer request: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error accepting organizer request: $e');
      rethrow;
    }
  }

  /// Manager rejects an event request from an organizer.
  static Future<void> rejectOrganizerRequest(String eventId, String reason) async {
    try {
      await client.from('events').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', eventId);
      
      if (kDebugMode) print('Manager rejected organizer request: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error rejecting organizer request: $e');
      rethrow;
    }
  }

  /// Manager reposts an accepted event to the volunteer dashboard.
  static Future<void> repostToVolunteers(String eventId, Map<String, dynamic> updatedData) async {
    try {
      await client.from('events').update({
        ...updatedData,
        'status': 'active',
      }).eq('id', eventId);
      
      if (kDebugMode) print('Event reposted to volunteers: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error reposting event: $e');
      rethrow;
    }
  }

  /// Manager accepts/applies for an event (standard application).
  static Future<void> acceptEvent(String eventId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await client.from('event_applications').insert({
        'event_id': eventId,
        'manager_id': user.id,
        'status': 'pending',
      });
      
      if (kDebugMode) print('Manager accepted event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error accepting event: $e');
      rethrow;
    }
  }

  /// Manager rejects/withdraws application for an event.
  static Future<void> rejectEvent(String eventId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await client.from('event_applications')
          .delete()
          .eq('event_id', eventId)
          .eq('manager_id', user.id);
      
      if (kDebugMode) print('Manager rejected event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error rejecting event: $e');
      rethrow;
    }
  }

  /// Fetches events the manager has already accepted.
  static Future<List<Map<String, dynamic>>> getAcceptedEvents() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final response = await client
          .from('event_applications')
          .select('*, events!event_applications_event_id_fkey(*)')
          .eq('manager_id', user.id);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('Error fetching accepted events: $e');
      return [];
    }
  }
  /// Fetches volunteers who have applied for a specific event.
  static Stream<List<Map<String, dynamic>>> getApplicantsStream(String eventId) {
    return client
        .from('event_applications')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return [];
          
          final volunteerIds = data.map((e) => e['volunteer_id']).toList();
          final usersResponse = await client
              .from('users')
              .select('id, full_name, email, phone_number, profile_photo')
              .inFilter('id', volunteerIds);
          
          final userMap = {for (var u in usersResponse) u['id']: u};
          return data.map((app) => {
            ...app,
            'volunteer': userMap[app['volunteer_id']],
          }).toList();
        });
  }
}

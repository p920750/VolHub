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

      // TODO: Replace with actual table queries once tables are created.
      // For now, we return "0" for all stats as placeholders, 
      // or we can try to query if tables exist.
      
      // Example of how it would look with real tables:
      // final activeTeamsCount = await client.from('teams').count().eq('manager_id', user.id).eq('status', 'active');
      // final totalMembersCount = ... (sum of members in teams)
      
      return {
        'Active Teams': '0',
        'Total Members': '0',
        'Open Job Postings': '0',
        'Pending Applications': '0',
        'Accepted Proposals': '0',
        'Pending Proposals': '0',
      };
    } catch (e) {
      if (kDebugMode) print('Error fetching dashboard stats: $e');
      return {
        'Active Teams': '-',
        'Total Members': '-',
        'Open Job Postings': '-',
        'Pending Applications': '-',
        'Accepted Proposals': '-',
        'Pending Proposals': '-',
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

      // Mock data until 'applications' table is set up
      /*
      final response = await client
          .from('applications')
          .select('*, events(name)')
          .eq('events.manager_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);
      */
      return [];
    } catch (e) {
      if (kDebugMode) print('Error fetching applications: $e');
      return [];
    }
  }

  /// Fetches recent proposals received by the current user.
  static Future<List<Map<String, dynamic>>> getRecentProposals() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

       // Mock data until 'proposals' table is set up
       /*
      final response = await client
          .from('proposals')
          .select('*, events(name)')
          .eq('events.manager_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);
      */
      return [];
    } catch (e) {
      if (kDebugMode) print('Error fetching proposals: $e');
      return [];
    }
  }

  /// Fetches pending event requests that match the manager's category.
  static Future<List<Map<String, dynamic>>> getEventRequests(String? category) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      var query = client.from('events').select('*, host:users(*)').eq('status', 'pending');
      
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);
      
      // Filter out events the manager has already accepted/applied for
      final appliedResponse = await client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List).map((e) => e['event_id']).toSet();

      return response.where((e) => !appliedIds.contains(e['id'])).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event requests: $e');
      return [];
    }
  }

  /// Manager accepts/applies for an event.
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
          .select('*, events(*)')
          .eq('manager_id', user.id);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('Error fetching accepted events: $e');
      return [];
    }
  }
}

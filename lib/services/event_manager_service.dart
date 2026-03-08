import 'dart:io';
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
          .or('assigned_manager_id.eq.${user.id},manager_ids.cs.{${user.id}}');
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
            .or('assigned_manager_id.eq.${user.id},manager_ids.cs.{${user.id}}');
            
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

      var query = client.from('events').select('*').eq('status', 'pending');
      
      query = query.inFilter('category', categories);
      
      query = query.neq('user_id', user.id); // Exclude own events

      final response = await query.order('created_at', ascending: false);
      
      final appliedResponse = await client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List?)?.map((e) => e['event_id']).toSet() ?? {};

      return response.map((e) {
        final Map<String, dynamic> eventMap = Map<String, dynamic>.from(e);
        eventMap['manager_has_applied'] = appliedIds.contains(eventMap['id']);
        // Fallback for ProposalDetailsScreen
        if (eventMap['host'] == null) {
          eventMap['host'] = {
            'full_name': eventMap['host_name'] ?? 'Organizer',
          };
        }
        return eventMap;
      }).toList();
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

      const selectColumns = '*'; 

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
          .or('assigned_manager_id.eq.${user.id},manager_ids.cs.{${user.id}}');

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

      return result.map((e) {
        if (e['host'] == null) {
          e['host'] = {
            'full_name': e['host_name'] ?? 'Organizer',
          };
        }
        e['manager_has_applied'] = appliedIds.contains(e['id']);
        return e;
      }).toList();
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

  /// Uploads media (photo/video) to the portfolio storage bucket.
  static Future<String?> uploadPortfolioMedia(File file) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';
      
      await client.storage.from('portfolio_media').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final String publicUrl = client.storage
          .from('portfolio_media')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      if (kDebugMode) print('Error uploading portfolio media: $e');
      return null;
    }
  }

  /// Adds a new portfolio item to the database.
  static Future<void> addPortfolioItem({
    required String eventName,
    required String eventType,
    required String roleHandled,
    String? outcomeSummary,
    List<String> photos = const [],
    List<String> videos = const [],
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await client.from('manager_portfolios').insert({
        'manager_id': user.id,
        'event_name': eventName,
        'event_type': eventType,
        'role_handled': roleHandled,
        'outcome_summary': outcomeSummary,
        'photos': photos,
        'videos': videos,
      });
    } catch (e) {
      if (kDebugMode) print('Error adding portfolio item: $e');
      rethrow;
    }
  }

  /// Returns a stream of portfolio items for the current manager.
  static Stream<List<Map<String, dynamic>>> getPortfolioStream() {
    final user = SupabaseService.currentUser;
    if (user == null) return const Stream.empty();

    return client
        .from('manager_portfolios')
        .stream(primaryKey: ['id'])
        .eq('manager_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Updates an existing portfolio item.
  static Future<void> updatePortfolioItem({
    required String id,
    required String eventName,
    required String eventType,
    required String roleHandled,
    String? outcomeSummary,
    List<String> photos = const [],
    List<String> videos = const [],
  }) async {
    try {
      await client.from('manager_portfolios').update({
        'event_name': eventName,
        'event_type': eventType,
        'role_handled': roleHandled,
        'outcome_summary': outcomeSummary,
        'photos': photos,
        'videos': videos,
      }).eq('id', id);
    } catch (e) {
      if (kDebugMode) print('Error updating portfolio item: $e');
      rethrow;
    }
  }

  /// Deletes a portfolio item.
  static Future<void> deletePortfolioItem(String id) async {
    try {
      await client.from('manager_portfolios').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) print('Error deleting portfolio item: $e');
      rethrow;
    }
  }

  /// Fetches volunteers who have applied for a specific event.
  static Stream<List<Map<String, dynamic>>> getApplicantsStream(String eventId) {
    return client
        .from('event_applications')
        .stream(primaryKey: ['event_id', 'volunteer_id'])
        .eq('event_id', eventId)
        .order('created_at', ascending: false)
        .map((data) => data.where((e) => e['manager_id'] == null || e['manager_id'] != e['volunteer_id']).toList()) // Filter for volunteer apps
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

  /// Manager accepts a volunteer's application.
  static Future<void> acceptVolunteer(String eventId, String volunteerId) async {
    try {
      // Use SECURITY DEFINER RPC to bypass RLS and increment count
      await client.rpc('accept_volunteer_safe', params: {
        'p_event_id': eventId,
        'p_volunteer_id': volunteerId,
      });

      if (kDebugMode) print('Manager accepted volunteer: $volunteerId for event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error accepting volunteer: $e');
      throw Exception('Failed to accept volunteer. Please ensure the safe RPCs are created in Supabase: $e');
    }
  }

  /// Manager rejects a volunteer's application.
  static Future<void> rejectVolunteer(String eventId, String volunteerId, [String? reason]) async {
    try {
      // Use SECURITY DEFINER RPC to bypass RLS and decrement count
      await client.rpc('reject_volunteer_safe', params: {
        'p_event_id': eventId,
        'p_volunteer_id': volunteerId,
      });

      if (kDebugMode) print('Manager rejected volunteer: $volunteerId for event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error rejecting volunteer: $e');
      throw Exception('Failed to reject volunteer: $e');
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
        'volunteer_id': user.id, // Bypass NOT NULL constraint on volunteer_id
        'status': 'pending',
      });
      
      // Update manager_ids array on events table directly so organizers can see it immediately
      final currentEvent = await client.from('events').select('manager_ids').eq('id', eventId).maybeSingle();
      if (currentEvent != null) {
        List<dynamic> currentManagers = List<dynamic>.from(currentEvent['manager_ids'] ?? []);
        if (!currentManagers.contains(user.id)) {
          currentManagers.add(user.id);
          await client.from('events').update({'manager_ids': currentManagers}).eq('id', eventId);
        }
      }
      
      if (kDebugMode) print('Manager accepted event: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error accepting event: $e');
      rethrow;
    }
  }

  /// Manager rejects/withdraws application for an event.
  static Future<void> rejectEvent(String eventId, [String? reason]) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await client.from('event_applications')
          .delete()
          .eq('event_id', eventId)
          .eq('manager_id', user.id);
          
      if (reason != null && reason.isNotEmpty) {
        final serializedReason = 'MANAGER_REJECTED::${user.id}::$reason';
        await client.from('events').update({
          'assigned_manager_id': null,
          'status': 'pending',
          'rejection_reason': serializedReason,
        }).eq('id', eventId);
      }
      
      // Keep manager_ids array on events synchronized
      final currentEvent = await client.from('events').select('manager_ids').eq('id', eventId).maybeSingle();
      if (currentEvent != null) {
        List<dynamic> currentManagers = List<dynamic>.from(currentEvent['manager_ids'] ?? []);
        if (currentManagers.contains(user.id)) {
          currentManagers.remove(user.id);
          await client.from('events').update({'manager_ids': currentManagers}).eq('id', eventId);
        }
      }

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

  /// Fetches events where the current user is a manager (for group chat lists).
  static Future<List<Map<String, dynamic>>> getActiveGroupChatsForManager() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final response = await client
          .from('events')
          .select('id, name, current_volunteers_count, volunteers_needed, image_url, created_at')
          .or('user_id.eq.${user.id},assigned_manager_id.eq.${user.id}')
          .neq('status', 'cancelled');

      final events = List<Map<String, dynamic>>.from(response);
      return events.where((e) {
        final current = (num.tryParse(e['current_volunteers_count']?.toString() ?? '0') ?? 0).toInt();
        final needed = (num.tryParse(e['volunteers_needed']?.toString() ?? '1') ?? 1).toInt();
        return current >= needed;
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching active group chats for manager: $e');
      return [];
    }
  }

  /// Fetches events where the current user is an accepted volunteer (for group chat lists).
  static Future<List<Map<String, dynamic>>> getActiveGroupChatsForVolunteer() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final response = await client
          .from('event_applications')
          .select('events(id, name, current_volunteers_count, volunteers_needed, image_url, created_at)')
          .eq('volunteer_id', user.id)
          .eq('status', 'accepted');

      final List<Map<String, dynamic>> eventsList = [];
      for (var row in response) {
        if (row['events'] != null) {
          final event = Map<String, dynamic>.from(row['events']);
          final current = (num.tryParse(event['current_volunteers_count']?.toString() ?? '0') ?? 0).toInt();
          final needed = (num.tryParse(event['volunteers_needed']?.toString() ?? '1') ?? 1).toInt();
          if (current >= needed) {
            eventsList.add(event);
          }
        }
      }
      return eventsList;
    } catch (e) {
      if (kDebugMode) print('Error fetching active group chats for volunteer: $e');
      return [];
    }
  }

  /// Returns a stream of application statuses for a specific volunteer.
  static Stream<List<Map<String, dynamic>>> getVolunteerApplicationsStream(String volunteerId) {
    return client
        .from('event_applications')
        .stream(primaryKey: ['event_id', 'volunteer_id'])
        .eq('volunteer_id', volunteerId)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Fetches members for a group chat (specific event).
  /// Includes the manager(s) and all accepted volunteers.
  static Future<List<Map<String, dynamic>>> getGroupMembers(String eventId) async {
    try {
      // Get the event details to find the manager and volunteers
      final event = await client
          .from('events')
          .select('user_id, assigned_manager_id, manager_ids, volunteer_ids')
          .eq('id', eventId)
          .maybeSingle();

      if (event == null) return [];

      List<String> userIds = [];

      // Add single manager (organizer) if present
      if (event['user_id'] != null) userIds.add(event['user_id'].toString());
      if (event['assigned_manager_id'] != null) userIds.add(event['assigned_manager_id'].toString());
      
      // Add manager array if present
      if (event['manager_ids'] != null) {
        userIds.addAll(List<dynamic>.from(event['manager_ids']).map((e) => e.toString()));
      }

      // Add volunteer array from event record if present
      if (event['volunteer_ids'] != null) {
        userIds.addAll(List<dynamic>.from(event['volunteer_ids']).map((e) => e.toString()));
      }

      // Also fetch accepted volunteers from event_applications table for consistency
      final applications = await client
          .from('event_applications')
          .select('volunteer_id')
          .eq('event_id', eventId)
          .eq('status', 'accepted');
      
      if (applications != null) {
        for (var app in applications) {
          userIds.add(app['volunteer_id'].toString());
        }
      }

      // Remove duplicates
      userIds = userIds.toSet().toList();

      if (userIds.isEmpty) return [];

      // Fetch user profiles for all IDs
      final usersResponse = await client
          .from('users')
          .select('id, full_name, profile_photo, email')
          .inFilter('id', userIds);

      final List<Map<String, dynamic>> members = [];
      for (var u in usersResponse) {
        final isManager = u['id'] == event['user_id'] || 
                          u['id'] == event['assigned_manager_id'] || 
                          (event['manager_ids'] != null && List<dynamic>.from(event['manager_ids']).contains(u['id']));
                          
        members.add({
          'id': u['id'],
          'name': u['full_name'] ?? 'Unknown',
          'avatar': u['profile_photo'] ?? '',
          'email': u['email'] ?? '',
          'role': isManager ? 'Manager' : 'Volunteer',
        });
      }

      // Sort managers first
      members.sort((a, b) {
        if (a['role'] == 'Manager' && b['role'] != 'Manager') return -1;
        if (a['role'] != 'Manager' && b['role'] == 'Manager') return 1;
        return a['name'].compareTo(b['name']);
      });

      return members;
    } catch (e) {
      if (kDebugMode) print('Error fetching group members: $e');
      return [];
    }
  }

  /// Volunteer backs out from an event they joined.
  static Future<void> backOutFromEvent(String eventId, String volunteerId, String reason) async {
    try {
      // 1. Update application status to 'withdrawn'
      await client
          .from('event_applications')
          .update({
            'status': 'withdrawn',
          })
          .eq('event_id', eventId)
          .eq('volunteer_id', volunteerId);

      // 2. Remove volunteer from the events table volunteer_ids array
      final currentEvent = await client
          .from('events')
          .select('volunteer_ids, current_volunteers_count')
          .eq('id', eventId)
          .maybeSingle();

      if (currentEvent != null) {
        List<dynamic> currentVolunteers = List<dynamic>.from(currentEvent['volunteer_ids'] ?? []);
        if (currentVolunteers.contains(volunteerId)) {
          currentVolunteers.remove(volunteerId);
          final currentCount = (currentEvent['current_volunteers_count'] ?? 0) as int;
          
          await client.from('events').update({
            'volunteer_ids': currentVolunteers,
            'current_volunteers_count': currentCount > 0 ? currentCount - 1 : 0,
          }).eq('id', eventId);
        }
      }

      if (kDebugMode) print('Volunteer $volunteerId backed out from event: $eventId. Reason: $reason');
    } catch (e) {
      if (kDebugMode) print('Error backing out from event: $e');
      rethrow;
    }
  }

  /// Updates group information (name, photo) for an event.
  static Future<void> updateEventGroupInfo({
    required String eventId,
    String? name,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (imageUrl != null) updates['image_url'] = imageUrl;

      if (updates.isEmpty) return;

      await client.from('events').update(updates).eq('id', eventId);
    } catch (e) {
      if (kDebugMode) print('Error updating event group info: $e');
      rethrow;
    }
  }
}


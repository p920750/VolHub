import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'host_service.dart';

class EventManagerService {
  static SupabaseClient get client => SupabaseService.client;

  /// Returns a stream of dashboard statistics for the current event manager.
  static Stream<Map<String, String>> getDashboardStatsStream() async* {
    final user = SupabaseService.currentUser;
    if (user == null) yield* const Stream.empty();

    // Initial load
    yield await getDashboardStats();

    // Listen to changes in events and teams relevant to the manager
    yield* Stream.periodic(const Duration(seconds: 30)).asyncMap((_) => getDashboardStats());
  }

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
      final teamsResponse = await client
          .from('teams')
          .select('id')
          .eq('manager_id', user.id);
      activeTeams = (teamsResponse as List?)?.length ?? 0;

      // 4. Active Members (Total volunteers in managed events)
      int activeMembers = 0;
      final eventsManaged = await client
          .from('events')
          .select('current_volunteers_count')
          .or('assigned_manager_id.eq.${user.id},manager_ids.cs.{${user.id}}');
          
      if (eventsManaged != null) {
        for (var e in eventsManaged as List) {
          activeMembers += int.tryParse(e['current_volunteers_count']?.toString() ?? '0') ?? 0;
        }
      }

      return {
        'Active Teams': activeTeams.toString(),
        'Active Members': activeMembers.toString(),
        'Accepted Proposals': acceptedProposals.toString(),
        'Pending Proposals': pendingProposals.toString(),
      };
    } catch (e) {
      if (kDebugMode) print('Error fetching dashboard stats: $e');
      return {
        'Active Teams': '0',
        'Active Members': '0',
        'Accepted Proposals': '0',
        'Pending Proposals': '0',
      };
    }
  }

  /// Fetches the list of teams managed by the current user.
  /// Also synchronizes by creating teams for filled events that don't have a team record yet.
  static Future<List<Map<String, dynamic>>> getTeams() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Fetch active group chats (filled events)
      final activeGroups = await getActiveGroupChatsForManager();
      
      // 2. Fetch existing teams
      final existingTeamsResponse = await client
          .from('teams')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final existingTeamEventIds = (existingTeamsResponse as List)
          .map((t) => t['event_id'].toString())
          .toSet();

      // 3. Synchronize: Create teams for filled events that are missing them
      for (var group in activeGroups) {
        final eventId = group['id'].toString();
        final currentCount = (num.tryParse(group['current_volunteers_count']?.toString() ?? '0') ?? 0).toInt();
        
        // Only create a team if there's at least one member (volunteer)
        if (!existingTeamEventIds.contains(eventId) && currentCount > 0) {
          await client.from('teams').insert({
            'event_id': eventId,
            'manager_id': user.id,
            'name': group['name'] ?? 'New Team',
          });
          if (kDebugMode) print('Auto-migrated filled event $eventId to teams table.');
        }
      }

      // 4. Fetch the updated list of teams
      final response = await client
          .from('teams')
          .select('*, events(name, image_url, current_volunteers_count)')
          .eq('manager_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).where((team) {
        final event = team['events'] as Map<String, dynamic>?;
        final currentCount = (num.tryParse(event?['current_volunteers_count']?.toString() ?? '0') ?? 0).toInt();
        return currentCount > 0; // Only return teams that have members
      }).map((team) {
        final event = team['events'] as Map<String, dynamic>?;
        return {
          'id': team['id'].toString(),
          'event_id': team['event_id'].toString(),
          'name': team['name'] ?? event?['name'] ?? 'Unnamed Team',
          'members': event?['current_volunteers_count'] ?? 0,
          'events': 1,
          'applications': 0,
          'avatars': [event?['image_url'] ?? ''],
        };
      }).toList();
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

      var query = client.from('events').select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)').eq('status', 'pending');
      
      query = query.inFilter('category', categories);
      
      query = query.neq('user_id', user.id); // Exclude own events

      final response = await query.order('created_at', ascending: false);
      
      final appliedResponse = await client
          .from('event_applications')
          .select('event_id')
          .eq('manager_id', user.id);
      
      final appliedIds = (appliedResponse as List?)?.map((e) => e['event_id']).toSet() ?? {};

      return response.where((e) {
        final settings = e['host']?['settings'] as Map<String, dynamic>?;
        return settings?['public_profile'] ?? true;
      }).map((e) {
        final Map<String, dynamic> eventMap = Map<String, dynamic>.from(e);
        eventMap['manager_has_applied'] = appliedIds.contains(eventMap['id']);
        
        // Populate host and format deadline
        final hostData = eventMap['host'] as Map<String, dynamic>?;
        eventMap['host'] = hostData ?? {'full_name': eventMap['host_name'] ?? 'Organizer'};
        eventMap['registration_deadline_formatted'] = HostService.formatDeadlineForMyEvents(eventMap['registration_deadline']);
        
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
            .select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)')
            .eq('status', 'pending')
            .neq('user_id', user.id) // Exclude own events
            .inFilter('category', categories);
      } else {
        if (kDebugMode) print('getProposals: No categories for manager ${user.id}');
      }
      
      // Filter by Public Profile
      if (pendingEvents is List && (pendingEvents as List).isNotEmpty) {
        pendingEvents = (pendingEvents as List).where((e) {
          final settings = e['host']?['settings'] as Map<String, dynamic>?;
          return settings?['public_profile'] ?? true;
        }).toList();
      }



      // 2. Events assigned to this manager
      final assignedEventsData = await client
          .from('events')
          .select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)')
          .or('assigned_manager_id.eq.${user.id},manager_ids.cs.{${user.id}}');
      final List<dynamic> assignedEvents = assignedEventsData as List<dynamic>? ?? [];

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
            .select('*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings)')
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
        final hostData = e['host'] as Map<String, dynamic>?;
        e['host'] = hostData ?? {'full_name': e['host_name'] ?? 'Organizer'};
        e['manager_has_applied'] = appliedIds.contains(e['id']);
        e['registration_deadline_formatted'] = HostService.formatDeadlineForMyEvents(e['registration_deadline']);
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
      
      try {
        final eventResponse = await client.from('events').select('user_id, name').eq('id', eventId).maybeSingle();
        if (eventResponse != null && eventResponse['user_id'] != null) {
          await client.from('notifications').insert({
            'user_id': eventResponse['user_id'],
            'event_id': eventId, // Reference back to the event
            'title': 'Proposal Accepted',
            'body': 'Managers have accepted your proposals for "${eventResponse['name']}".',
            'type': 'acceptance',
          });
        }
      } catch (e) {
        if (kDebugMode) print('Error sending notification: $e');
      }

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

  /// Manager marks an event as finished/completed.
  /// This updates the status to 'finished' which the UI displays as 'Completed by Manager'.
  static Future<void> markEventAsFinished(String eventId, String notes) async {
    try {
      await client.from('events').update({
        'status': 'finished',
        'manager_completion_notes': notes,
      }).eq('id', eventId);
      
      if (kDebugMode) print('Manager marked event as finished: $eventId');
    } catch (e) {
      if (kDebugMode) print('Error marking event as finished: $e');
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

      // Manager accepts a volunteer's application.
  static Future<void> acceptVolunteer(String eventId, String volunteerId) async {
    try {
      // 1. Accept the volunteer via safe RPC
      await client.rpc('accept_volunteer_safe', params: {
        'p_event_id': eventId,
        'p_volunteer_id': volunteerId,
      });

      // 2. Check if the event is now completely filled
      final eventResponse = await client
          .from('events')
          .select('name, volunteers_needed, current_volunteers_count, user_id')
          .eq('id', eventId)
          .maybeSingle();

      if (eventResponse != null) {
        final needed = int.tryParse(eventResponse['volunteers_needed']?.toString() ?? '0') ?? 0;
        final current = int.tryParse(eventResponse['current_volunteers_count']?.toString() ?? '0') ?? 0;
        final organizerId = eventResponse['user_id'];
        final assignedManagerId = eventResponse['assigned_manager_id'];

        if (current >= needed && needed > 0) {
          // Check if a team already exists for this event
          final existingTeam = await client
              .from('teams')
              .select('id')
              .eq('event_id', eventId)
              .maybeSingle();

          if (existingTeam == null) {
            // Create a new team record automatically as slots are now completely filled
            // Ensure the manager_id is the assigned manager if present
            await client.from('teams').insert({
              'event_id': eventId,
              'manager_id': assignedManagerId ?? organizerId,
              'name': eventResponse['name'] ?? 'New Team',
            });
            if (kDebugMode) print('Team automatically created for event $eventId as slots are filled.');
          }
        }
      }

      if (kDebugMode) print('Manager accepted volunteer: $volunteerId for event: $eventId');

      // Notify the volunteer about the acceptance
      try {
        if (eventResponse != null) {
          final eventName = eventResponse['name'] ?? 'an event';
          await client.from('notifications').insert({
            'user_id': volunteerId,
            'event_id': eventId,
            'title': 'Application Accepted!',
            'body': 'Congratulations! You have been accepted for the event "$eventName".',
            'type': 'acceptance',
          });
        }
      } catch (notifyError) {
        if (kDebugMode) print('Error sending volunteer acceptance notification: $notifyError');
      }
    } catch (e) {
      if (kDebugMode) print('Error accepting volunteer: $e');
      throw Exception('Failed to accept volunteer: $e');
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

      // Notify the volunteer about the rejection
      try {
        final eventResponse = await client
            .from('events')
            .select('name')
            .eq('id', eventId)
            .maybeSingle();

        if (eventResponse != null) {
          final eventName = eventResponse['name'] ?? 'an event';
          await client.from('notifications').insert({
            'user_id': volunteerId,
            'event_id': eventId,
            'title': 'Application Update',
            'body': 'Your application for "$eventName" was not successful.',
            'type': 'proposal',
          });
        }
      } catch (notifyError) {
        if (kDebugMode) print('Error sending volunteer rejection notification: $notifyError');
      }
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
      final currentEvent = await client.from('events').select('manager_ids, user_id, name').eq('id', eventId).maybeSingle();
      if (currentEvent != null) {
        List<dynamic> currentManagers = List<dynamic>.from(currentEvent['manager_ids'] ?? []);
        if (!currentManagers.contains(user.id)) {
          currentManagers.add(user.id);
          await client.from('events').update({'manager_ids': currentManagers}).eq('id', eventId);
        }
        
        try {
          if (currentEvent['user_id'] != null) {
            await client.from('notifications').insert({
              'user_id': currentEvent['user_id'],
              'event_id': eventId, // Reference back to the event
              'title': 'Managers have accepted your proposals',
              'body': 'Managers have accepted your proposals for "${currentEvent['name'] ?? 'your event'}".',
              'type': 'acceptance',
            });
          }
        } catch (e) {
          if (kDebugMode) print('Error sending notification: $e');
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
        
        // Notify the organizer about the withdrawal
        try {
          final eventResponse = await client
              .from('events')
              .select('name, user_id')
              .eq('id', eventId)
              .maybeSingle();

          final userResponse = await client
              .from('users')
              .select('full_name')
              .eq('id', user.id)
              .maybeSingle();

          if (eventResponse != null && userResponse != null) {
            final organizerId = eventResponse['user_id'];
            final eventName = eventResponse['name'] ?? 'an event';
            final managerName = userResponse['full_name'] ?? 'A manager';
            
            await client.from('notifications').insert({
              'user_id': organizerId,
              'event_id': eventId,
              'title': 'Manager Withdrawal',
              'body': '$managerName has withdrawn from "$eventName". Reason: $reason',
              'type': 'proposal',
            });
          }
        } catch (e) {
          if (kDebugMode) print('Error sending notification on manager withdrawal: $e');
        }
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
        // A group chat only exists if there are volunteers (members)
        return current > 0;
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
          // A group chat only exists if there are volunteers (members)
          if (current > 0) {
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

      // Add assigned manager if present
      if (event['assigned_manager_id'] != null) {
        userIds.add(event['assigned_manager_id'].toString());
      } else if (event['user_id'] != null) {
        // If no manager is assigned, then the owner (organizer) acts as the manager
        userIds.add(event['user_id'].toString());
      }
      
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
        final isManager = u['id'] == (event['assigned_manager_id'] ?? event['user_id']) || 
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

      // Notify the manager about the volunteer backing out
      try {
        final managerResponse = await client
            .from('event_applications')
            .select('manager_id')
            .eq('event_id', eventId)
            .eq('volunteer_id', volunteerId)
            .maybeSingle();
        
        final eventResponse = await client
            .from('events')
            .select('name')
            .eq('id', eventId)
            .maybeSingle();

        final userResponse = await client
            .from('users')
            .select('full_name')
            .eq('id', volunteerId)
            .maybeSingle();

        if (managerResponse != null && eventResponse != null && userResponse != null) {
          final managerId = managerResponse['manager_id'];
          final eventName = eventResponse['name'] ?? 'an event';
          final volunteerName = userResponse['full_name'] ?? 'A volunteer';

          await client.from('notifications').insert({
            'user_id': managerId,
            'event_id': eventId,
            'title': 'Volunteer Backed Out',
            'body': '$volunteerName has backed out from "$eventName". Reason: $reason',
            'type': 'withdrawal',
          });
        }
      } catch (notifyError) {
        if (kDebugMode) print('Error sending manager notification on volunteer back out: $notifyError');
      }
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

      if (updates.isNotEmpty) {
        await client.from('events').update(updates).eq('id', eventId);
        
        // Also update team name if it exists
        if (name != null) {
          await client.from('teams').update({'name': name}).eq('event_id', eventId);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error updating event group info: $e');
      throw e;
    }
  }

  /// Removes a member from a team/event group.
  static Future<void> removeTeamMember(String eventId, String volunteerId) async {
    try {
      // 1. Update application status to rejected so they lose chat access
      // Note: event_applications doesn't have rejection_reason column
      await client
          .from('event_applications')
          .update({'status': 'rejected'})
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

      if (kDebugMode) print('Removed member $volunteerId from event $eventId');
    } catch (e) {
      if (kDebugMode) print('Error removing team member: $e');
      throw e;
    }
  }

  /// Deletes a team and clears chat history (effectively clears receiver_id = eventId)
  static Future<void> deleteTeam(String teamId, String eventId) async {
    try {
      // 1. Delete team record
      await client.from('teams').delete().eq('id', teamId);

      // 2. Clear messages for this event (group chat)
      await client.from('messages').delete().eq('receiver_id', eventId);

      // 3. Mark event as pending/cancelled or just leave it? 
      // Re-opening the event to new applicants might be desired, but for now we just delete the team.
      
      if (kDebugMode) print('Deleted team $teamId and cleared chat for $eventId');
    } catch (e) {
      if (kDebugMode) print('Error deleting team: $e');
      throw e;
    }
  }

  /// Fetches recent volunteer applications for events managed by the current manager.
  static Future<List<Map<String, dynamic>>> getRecentVolunteerApplications() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final response = await client
          .from('event_applications')
          .select('*, volunteer:users!volunteer_id(full_name, profile_photo), events(*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings))')
          .eq('manager_id', user.id)
          .neq('volunteer_id', user.id) // Exclude manager's own applications
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((app) => {
        'name': app['volunteer']?['full_name'] ?? 'Unknown Volunteer',
        'role': app['events']?['category'] ?? 'Volunteer',
        'status': app['status'],
        'date': app['created_at'],
        'avatarUrl': app['volunteer']?['profile_photo'],
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching recent applications: $e');
      return [];
    }
  }

  /// Fetches recent proposals (applications) sent by the manager to organizers.
  static Future<List<Map<String, dynamic>>> getRecentManagerProposals() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final response = await client
          .from('event_applications')
          .select('*, events(*, host:users!user_id(id, full_name, email, phone_number, company_location, profile_photo, settings))')
          .eq('manager_id', user.id)
          .eq('volunteer_id', user.id) // Manager as the "volunteer" (applier)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((app) => {
        'event': app['events']?['name'] ?? 'Unknown Event',
        'budget': app['events']?['budget'] ?? 'N/A',
        'status': app['status'],
        'date': app['created_at'],
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching recent proposals: $e');
      return [];
    }
  }
}

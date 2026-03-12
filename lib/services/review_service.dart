import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ReviewService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<void> submitReview({
    required String eventId,
    required String organizerId,
    required String managerId,
    required double overallRating,
    required double communicationRating,
    required double leadershipRating,
    required double planningRating,
    required double problemSolvingRating,
    required double executionRating,
    required String feedback,
    required bool workAgain,
  }) async {
    await _client.from('manager_reviews').insert({
      'event_id': eventId,
      'organizer_id': organizerId,
      'manager_id': managerId,
      'overall_rating': overallRating,
      'communication_rating': communicationRating,
      'leadership_rating': leadershipRating,
      'planning_rating': planningRating,
      'problem_solving_rating': problemSolvingRating,
      'execution_rating': executionRating,
      'feedback': feedback,
      'work_again': workAgain,
    });
  }

  static Future<List<Map<String, dynamic>>> getReviewsForManager(String managerId) async {
    final response = await _client
        .from('manager_reviews')
        .select('*, organizer:users!organizer_id(*), event:events!event_id(*)')
        .eq('manager_id', managerId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getReviewForEvent(String eventId, String managerId) async {
    final response = await _client
        .from('manager_reviews')
        .select()
        .eq('event_id', eventId)
        .eq('manager_id', managerId)
        .maybeSingle();
    
    return response;
  }
}

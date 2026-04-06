import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class VolunteerService {
  static final client = Supabase.instance.client;

  /// Fetches top 20 volunteers for the leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    try {
      final response = await client
          .from('users')
          .select('id, full_name, profile_photo, rank_score')
          .eq('role', 'volunteer')
          .order('rank_score', ascending: false)
          .limit(20);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Calculates the rank of a specific volunteer
  static Future<int> getUserRank(String userId) async {
    try {
      final userResponse = await client
          .from('users')
          .select('rank_score')
          .eq('id', userId)
          .single();
      
      final score = userResponse['rank_score'] ?? 0;

      // Count users with higher score to determine rank
      final countResponse = await client
          .from('users')
          .select('id')
          .eq('role', 'volunteer')
          .gt('rank_score', score);
      
      return (countResponse as List).length + 1;
    } catch (e) {
      print('Error calculating user rank: $e');
      return 0;
    }
  }

  /// Fetches simple user stats for the volunteer
  static Future<Map<String, dynamic>> getVolunteerStats(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('rank_score, profile_completeness')
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching stats: $e');
      return {'rank_score': 0, 'profile_completeness': 0};
    }
  }
}

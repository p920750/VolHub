import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/event_manager_service.dart';
import '../../../../services/review_service.dart';
import '../../../../services/supabase_service.dart';

final recentApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await EventManagerService.getRecentVolunteerApplications();
});

final recentProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await EventManagerService.getRecentManagerProposals();
});

final recentReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final managerId = SupabaseService.currentUser?.id;
  if (managerId == null) return [];
  return await ReviewService.getReviewsForManager(managerId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/event_manager_service.dart';

final recentApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await EventManagerService.getRecentVolunteerApplications();
});

final recentProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await EventManagerService.getRecentManagerProposals();
});

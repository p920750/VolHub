import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/event_manager_service.dart';

final dashboardStatsProvider = StreamProvider<Map<String, String>>((ref) {
  return EventManagerService.getDashboardStatsStream();
});
